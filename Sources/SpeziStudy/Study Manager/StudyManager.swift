//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Combine
import Foundation
import Spezi
import SpeziFoundation
import SpeziHealthKit
import SpeziLocalStorage
@_spi(APISupport)
import SpeziScheduler
import SpeziSchedulerUI
@_documentation(visibility: internal)
@_exported import SpeziStudyDefinition
import SwiftData
import SwiftUI
#if canImport(UIKit) && !os(watchOS)
import class UIKit.UIApplication
#endif


/// Manages enrollment and participation in studies.
///
/// ## Usage
///
/// The ``StudyManager`` module handles enrollment into Studies, and coordinates the scheduling of a study's components.
///
/// ## Topics
///
/// ### Initialization
/// - ``init(preferredLocale:persistence:)``
///
/// ### Study Enrollment
/// - ``enroll(in:)``
/// - ``unenroll(from:)``
/// - ``informAboutStudies(_:)``
/// - ``StudyEnrollment``
/// - ``StudyEnrollmentError``
///
/// ### Instance Properties
/// - ``preferredLocale``
@MainActor
public final class StudyManager: Module, EnvironmentAccessible, Sendable {
    /// How the ``StudyManager`` should persist its data.
    public enum PersistenceConfiguration {
        /// The ``StudyManager`` will use an on-disk database for persistence.
        case onDisk
        /// The ``StudyManager`` will use an in-memory database for persistence.
        /// Intended primarily for testing purposes.
        case inMemory
    }
    
    // ISSUE: on a mac, this will end up writing to ~/Documents (bad!)
    nonisolated static let studyBundlesDirectory = URL.documentsDirectory
        .appending(path: "edu.stanford.SpeziStudy/StudyBundles", directoryHint: .isDirectory)
    
    /// The prefix used for SpeziScheduler Tasks created for study component schedules.
    private static let speziStudyDomainTaskIdPrefix = "edu.stanford.spezi.SpeziStudy.studyComponentTask."
    
    
    // swiftlint:disable attributes
    @Dependency(HealthKit.self) var healthKit
    @Dependency(Scheduler.self) var scheduler
    @Application(\.logger) var logger
    // swiftlint:enable attributes
    
    /// The `Locale` the study manager should use when loading localized elements from a Study Bundle.
    ///
    /// This value affects e.g. the titles used for scheduled tasks and their resulting notifications.
    public var preferredLocale: Locale {
        didSet {
            guard preferredLocale.language != oldValue.language || preferredLocale.region != oldValue.region else {
                return
            }
            handleLocaleUpdate()
        }
    }
    
    #if targetEnvironment(simulator)
    private var autosaveTask: _Concurrency.Task<Void, Never>?
    #endif
    
    let modelContainer: ModelContainer
    
    var modelContext: ModelContext {
        modelContainer.mainContext
    }
    
    private var outcomesObserverToken: AnyObject?
    
    /// All ``StudyEnrollment``s currently registered with the ``StudyManager``.
    public var studyEnrollments: [StudyEnrollment] {
        (try? modelContext.fetch(FetchDescriptor<StudyEnrollment>())) ?? []
    }
    
    /// Creates a new Study Manager, using the specified persistence configuration
    ///
    /// - parameter preferredLocale: The `Locale` which should be used when
    public nonisolated init(
        preferredLocale: Locale = .autoupdatingCurrent,
        persistence: PersistenceConfiguration = .onDisk
    ) {
        self.preferredLocale = preferredLocale
        self.modelContainer = { () -> ModelContainer in
            let schema = Schema([StudyEnrollment.self], version: Schema.Version(0, 0, 2))
            let config: ModelConfiguration
            switch persistence {
            case .onDisk:
                guard ProcessInfo.isRunningInSandbox else {
                    preconditionFailure(
                        """
                        The current application is running in a non-sandboxed environment.
                        In this case, the `onDisk` persistence configuration is not available,
                        since the \(StudyManager.self) module would end up placing its database directly into
                        the current user's Documents directory (i.e., `~/Documents`).
                        Specify another persistence option, or enable sandboxing for the application.
                        """
                    )
                }
                config = ModelConfiguration(
                    "SpeziStudy",
                    schema: schema,
                    url: URL.documentsDirectory.appendingPathComponent("edu.stanford.spezi.studymanager.storage.sqlite")
                )
            case .inMemory:
                config = ModelConfiguration("SpeziStudy", schema: schema, isStoredInMemoryOnly: true)
            }
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
    }
    
    
    @_documentation(visibility: internal)
    public func configure() { // swiftlint:disable:this function_body_length
        typealias Task = _Concurrency.Task
        Task { @MainActor in
            let enrollments = try modelContext.fetch(FetchDescriptor<StudyEnrollment>())
            try registerStudyTasksWithScheduler(for: enrollments)
            try await setupStudyBackgroundComponents(for: enrollments)
            try removeOrphanedTasks()
            try removeOrphanedStudyBundles()
            #if targetEnvironment(simulator)
            if autosaveTask == nil {
                autosaveTask = Task.detached {
                    while true {
                        await MainActor.run {
                            try? self.modelContext.save()
                        }
                        try? await Task.sleep(for: .seconds(0.25))
                    }
                }
            }
            #endif
            outcomesObserverToken = scheduler.observeNewOutcomes { [weak self] outcome in
                guard let self,
                      let studyContext = outcome.task.studyContext,
                      let studyBundle = self.studyEnrollments.first(where: { $0.studyId == studyContext.studyId })?.studyBundle else {
                    return
                }
                self.handleStudyLifecycleEvent(
                    .completedTask(componentId: studyContext.componentId),
                    for: studyBundle,
                    at: .now
                )
            }
        }
        
        Task { [weak self] in
            let localeUpdates = NotificationCenter.default.notifications(named: NSLocale.currentLocaleDidChangeNotification)
            for await _ in localeUpdates {
                guard let self else {
                    return
                }
                if self.preferredLocale == .autoupdatingCurrent {
                    self.handleLocaleUpdate()
                }
            }
        }
        #if canImport(UIKit) && !os(watchOS)
        Task { [weak self] in
            let timeUpdates = NotificationCenter.default.notifications(named: UIApplication.significantTimeChangeNotification)
            for await _ in timeUpdates {
                guard let self else {
                    return
                }
                self.handleLocaleUpdate()
            }
        }
        #endif
    }
    
    
    @MainActor
    func sinkDidSavePublisher(into consume: @MainActor @escaping (Notification) -> Void) throws -> AnyCancellable {
        NotificationCenter.default.publisher(for: ModelContext.didSave, object: modelContainer.mainContext)
            .sink { notification in
                // We use the mainContext. Therefore, the vent will always be called from the main actor
                MainActor.assumeIsolated {
                    consume(notification)
                }
            }
    }
}


// MARK: Study Participation and Lifecycle Management

extension StudyManager {
    public enum StudyEnrollmentError: Error, LocalizedError {
        /// The user tried to enroll into a study with revision `X`, but they are already enrolled in revision `Y > X`.
        case alreadyEnrolledInNewerStudyRevision
        /// The user tried to enroll into a study which defines a depdenency on some other study, which the user isn't enrolled in.
        case missingEnrollmentInStudyDependency
        
        public var errorDescription: String? {
            switch self {
            case .alreadyEnrolledInNewerStudyRevision:
                "Already enrolled in a newer version of this study"
            case .missingEnrollmentInStudyDependency:
                "Cannot enroll in this study at this time, because the study has a dependency on another study, which the user is not enrolled in"
            }
        }
    }
    
    private enum TaskCreationError: Error {
        /// Attempted to create a `Task` for a component which cannot be scheduled (eg: a health data collection component)
        case componentNotEligibleForTaskCreation
        /// Asked to create a `Task` for an invalid `ComponentSchedule`, e.g. because the referenced component doesn't exist.
        case unableToFindComponent
    }
    
    
    @MainActor // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func registerStudyTasksWithScheduler(for enrollments: some Collection<StudyEnrollment>) throws {
        for enrollment in enrollments {
            guard let studyBundle = enrollment.studyBundle else {
                continue
            }
            let study = studyBundle.studyDefinition
            /// The IDs of all Tasks belonging to this study we consider to be "active" (i.e., we don't want to delete).
            var activeTaskIds = Set<Task.ID>()
            for schedule in study.componentSchedules {
                guard let component: StudyDefinition.Component = study.component(withId: schedule.componentId) else {
                    // ideally this shouldn't happen, but if it does (we have a schedule but can't resolve the corresponding component),
                    // we simply skip and ignore it.
                    continue
                }
                switch component.kind {
                case .userInteractive:
                    // user-interactive components get scheduled as Scheduler Tasks ...
                    break
                case .internal:
                    // ... but internal components don't
                    continue
                }
                let taskSchedule: SpeziScheduler.Schedule
                switch schedule.scheduleDefinition {
                case .once(.event):
                    let taskId = taskId(for: schedule, in: studyBundle)
                    activeTaskIds.insert(taskId)
                    if let task = try scheduler.queryTasks(
                        for: Date.distantPast..<Date.distantFuture,
                        predicate: #Predicate<Task> { $0.id == taskId }
                    ).first?.latestVersion {
                        // there already exists a Task for this event-based schedule,
                        // meaning that the event has already occurred at some point in the past.
                        // since the locale may have changed, we now need to re-register the Task,
                        // in order to get an updated version that is created using the new locale.
                        // Note that we intentionally reuse the old task's schedule here, since it
                        // likely is a Date-based one-time schedule.
                        _ = try createOrUpdateTask(componentSchedule: schedule, enrollment: enrollment, taskSchedule: task.schedule)
                    }
                    continue
                case .once(.date(let dateComponents)):
                    guard let date = preferredLocale.calendar.date(from: dateComponents) else {
                        continue
                    }
                    taskSchedule = .once(at: date, duration: .tillEndOfDay)
                case .repeated:
                    taskSchedule = .fromRepeated(
                        schedule.scheduleDefinition,
                        in: preferredLocale.calendar,
                        participationStartDate: enrollment.enrollmentDate
                    )
                }
                do {
                    let task = try createOrUpdateTask(
                        componentSchedule: schedule,
                        enrollment: enrollment,
                        taskSchedule: taskSchedule
                    )
                    activeTaskIds.insert(task.id)
                } catch TaskCreationError.unableToFindComponent, TaskCreationError.componentNotEligibleForTaskCreation {
                    continue
                } catch {
                    throw error
                }
            }
            let prefix = taskIdPrefix(for: studyBundle)
            let orphanedTasks = (try? scheduler.queryTasks(for: Date.distantPast...Date.distantFuture, predicate: #Predicate<Task> {
                // we filter for all tasks that are part of this study (determined based on prefix),
                // and are not among the tasks we just scheduled.
                // any task that exists in the scheduler and does not fulfill these criteria is a task that must have been scheduled
                // for a previous revision of the study, and belongs to a component that no longer exists
                $0.id.starts(with: prefix) && !activeTaskIds.contains($0.id)
            })) ?? []
            for orphanedTask in orphanedTasks {
                logger.notice("Deleting orphaned Task for study '\(study.metadata.title)' (\(study.id)): \(orphanedTask)")
                try scheduler.deleteAllVersions(of: orphanedTask)
            }
        }
    }
    
    
    /// Creates (or updates) a `Task` for a study component, based on a schedule.
    @MainActor
    private func createOrUpdateTask( // swiftlint:disable:this function_body_length
        componentSchedule: StudyDefinition.ComponentSchedule,
        enrollment: StudyEnrollment,
        taskSchedule: SpeziScheduler.Schedule
    ) throws -> Task {
        guard let studyBundle = enrollment.studyBundle,
              let component = studyBundle.studyDefinition.component(withId: componentSchedule.componentId) else {
            throw TaskCreationError.unableToFindComponent
        }
        logger.notice("Asked to create Task for \(String(describing: component)) w/ schedule \(String(describing: componentSchedule))")
        let category: Task.Category?
        let action: ScheduledTaskAction?
        switch component {
        case .questionnaire(let component):
            category = .questionnaire
            action = .answerQuestionnaire(component)
        case .informational(let component):
            category = .informational
            action = .presentInformationalStudyComponent(component)
        case .timedWalkingTest(let component):
            category = switch component.test.kind {
            case .walking: .timedWalkingTest
            case .running: .timedRunningTest
            }
            action = .promptTimedWalkingTest(component)
        case .customActiveTask(let component):
            category = .customActiveTask(component.activeTask)
            action = .performCustomActiveTask(component)
        case .healthDataCollection:
            throw TaskCreationError.componentNotEligibleForTaskCreation
        }
        return try scheduler.createOrUpdateTask(
            id: taskId(for: componentSchedule, in: studyBundle),
            title: studyBundle.displayTitle(for: component, in: preferredLocale).map { "\($0)" } ?? "",
            instructions: studyBundle.displaySubtitle(for: component, in: preferredLocale).map { "\($0)" } ?? "",
            category: category,
            schedule: taskSchedule,
            completionPolicy: componentSchedule.completionPolicy,
            scheduleNotifications: {
                switch componentSchedule.notifications {
                case .disabled: false
                case .enabled: true
                }
            }(),
            notificationThread: componentSchedule.notifications.thread,
            notificationTime: componentSchedule.notifications.time,
            tags: nil,
            effectiveFrom: .now,
            shadowedOutcomesHandling: .delete,
            with: { context in
                context.studyContext = .init(
                    studyId: studyBundle.studyDefinition.id,
                    componentId: component.id,
                    scheduleId: componentSchedule.id,
                    enrollmentId: enrollment.persistentModelID
                )
                context.studyScheduledTaskAction = action
            }
        ).task
    }
    
    
    @MainActor
    private func setupStudyBackgroundComponents(for enrollments: some Collection<StudyEnrollment>) async throws {
        for enrollment in enrollments {
            guard let studyBundle = enrollment.studyBundle else {
                continue
            }
            func setupSampleCollection<Sample>(_ sampleType: some AnySampleType<Sample>) async {
                let sampleType = SampleType(sampleType)
                await healthKit.addHealthDataCollector(CollectSample(
                    sampleType,
                    start: .automatic,
                    continueInBackground: true
                ))
            }
            for component in studyBundle.studyDefinition.healthDataCollectionComponents {
                for sampleType in component.sampleTypes {
                    await setupSampleCollection(sampleType)
                }
            }
        }
        // we want to request HealthKit auth once, at the end, for everything we just registered.
        try await healthKit.askForAuthorization()
    }
    
    
    private func taskIdPrefix(for studyBundle: StudyBundle) -> String {
        taskIdPrefix(forStudyId: studyBundle.id)
    }
    
    private func taskIdPrefix(forStudyId studyId: StudyBundle.ID) -> String {
        Self.speziStudyDomainTaskIdPrefix + studyId.uuidString
    }
    
    private func taskId(for schedule: StudyDefinition.ComponentSchedule, in studyBundle: StudyBundle) -> String {
        "\(taskIdPrefix(for: studyBundle)).\(schedule.componentId).\(schedule.id)"
    }
    
    // MARK: Study Enrollment
    
    /// Enroll in a study.
    ///
    /// Once the device is enrolled into a study at revision `X`, subsequent ``enroll(in:)`` calls for the same study, with revision `Y`, will:
    /// - if `X = Y`: have no effect;
    /// - if `X < Y`: update the study enrollment, as if ``informAboutStudies(_:)`` was called with the new study revision;
    /// - if `X > Y`: throw an error.
    ///
    /// - parameter studyBundle: The `StudyBundle` to enroll into.
    /// - parameter enrollmentDate: The `Date` relative to which the enrollment should be registered.
    ///     This defaults to the current date, but you can override this to specify a date in the past if you re-enroll a user which was already enrolled before.
    @MainActor
    public func enroll(in studyBundle: StudyBundle, enrollmentDate: Date = .now) async throws {
        let study = studyBundle.studyDefinition
        // big issue in this function is that, if we throw somewhere we kinda need to unroll _all_ the changes we've made so far
        // (which is much easier said than done...)
        let enrollments = try modelContext.fetch(FetchDescriptor<StudyEnrollment>())
        
        if case let existingEnrollments = enrollments.filter({ $0.studyId == studyBundle.id }),
           !existingEnrollments.isEmpty {
            // There exists at least one enrollment for this study
            if let enrollment = existingEnrollments.first, existingEnrollments.count == 1 {
                if enrollment.studyRevision == study.studyRevision {
                    // already enrolled in this study, at this revision.
                    // this is a no-op.
                    logger.notice("Ignoring enrollment request bc we're already enrolled, at this revision.")
                    return
                } else if enrollment.studyRevision < study.studyRevision {
                    // if we have only one enrollment, and it is for an older version of the study,
                    // we treat the enroll call as a study definition update
                    logger.notice("Already enrolled in older version of the study; fwd'ing to -informAboutStudies.")
                    try await informAboutStudies(CollectionOfOne(studyBundle))
                    return
                } else {
                    // enrollment.studyRevision > study.studyRevision
                    // trying to enroll into an older version of the study.
                    throw StudyEnrollmentError.alreadyEnrolledInNewerStudyRevision
                }
            }
            throw StudyEnrollmentError.alreadyEnrolledInNewerStudyRevision
        }
        
        if let dependency = study.metadata.studyDependency {
            guard enrollments.contains(where: { $0.studyId == dependency }) else {
                throw StudyEnrollmentError.missingEnrollmentInStudyDependency
            }
        }
        
        let enrollment = try StudyEnrollment(enrollmentDate: enrollmentDate, studyBundle: studyBundle)
        modelContext.insert(enrollment)
        try modelContext.save()
        try registerStudyTasksWithScheduler(for: CollectionOfOne(enrollment))
        // intentionally doing this before the background component setup, since that call is async and might take several seconds to return
        // (bc of the HealthKit permissions)
        if preferredLocale.calendar.isDateInToday(enrollmentDate) {
            // if we enrolled for the current day, we trigger the enrollment-event-based component scheduled.
            // we intentionally skip this if the enrollment is for a different date.
            handleStudyLifecycleEvent(.enrollment, for: studyBundle, at: enrollmentDate)
        }
        handleStudyLifecycleEvent(.activation, for: studyBundle, at: .now)
        try await setupStudyBackgroundComponents(for: CollectionOfOne(enrollment))
    }
    
    
    /// Unenroll from a study.
    public func unenroll(from enrollment: StudyEnrollment) throws {
        logger.notice("Unenrolling from study '\(enrollment.studyId)' (\(enrollment.studyBundle?.studyDefinition.metadata.title ?? "n/a"))")
        do {
            // Delete all Tasks associated with this study.
            // Note that we do this by simply fetching & deleting all Tasks with a matching prefix,
            // instead of going (based on the study components) through all component ids and deleting the tasks based on that.
            // the reason being that we might be deleting an enrollment w/ an old study schema, which we can't necessarily trivially decode.
            let studyTaskPrefix = taskIdPrefix(forStudyId: enrollment.studyId)
            let tasks = try scheduler.queryTasks(for: Date.distantPast...Date.distantFuture, predicate: #Predicate {
                $0.id.starts(with: studyTaskPrefix)
            })
            for task in tasks {
                try scheduler.deleteAllVersions(of: task)
            }
        }
        let studyBundleUrl = enrollment.studyBundleUrl
        modelContext.delete(enrollment)
        try? FileManager.default.removeItem(at: studyBundleUrl)
        try modelContext.save()
    }
    
    
    /// Fetches the ``StudyEnrollment`` for the specified `PersistentIdentifier`.
    public func enrollment(withId id: PersistentIdentifier) -> StudyEnrollment? {
        // for some reason, simply doing `modelContext.registeredModel(for: id)` doesn't work...
        let enrollments = (try? modelContext.fetch(FetchDescriptor(predicate: #Predicate<StudyEnrollment> {
            $0.persistentModelID == id
        }))) ?? []
        return enrollments.first
    }
    
    
    /// Removes all SpeziScheduler Tasks which are in the SpeziStudy domain (based on the task id's prefix), but for which we don't have any matching study enrollments.
    @_spi(TestingSupport)
    public func removeOrphanedTasks() throws {
        let activeStudyIds = try modelContext.fetch(FetchDescriptor<StudyEnrollment>()).mapIntoSet(\.studyId)
        // Note: it sadly seems like we can't use a #Predicate to filter through SwiftData here. (doing so will simply crash the app...)
        let orphanedTasks = try scheduler.queryTasks(for: Date.distantPast...Date.distantFuture).filter { task in
            // fetch all tasks which are in the SpeziStudy domain, but don't match one of the currently-enrolled-in studies.
            task.id.starts(with: Self.speziStudyDomainTaskIdPrefix) && !activeStudyIds.contains { task.id.starts(with: taskIdPrefix(forStudyId: $0)) }
        }
        for task in orphanedTasks {
            logger.notice("Found orphaned task in SpeziStudy domain which doesn't match any current enrollment: '\(task.id)'. Will delete.")
            try scheduler.deleteAllVersions(of: task)
        }
    }
    
    /// Removes all entries in the ``StudyManager/studyBundlesDirectory`` which do not correspond to one of the current study enrollments.
    @_spi(TestingSupport)
    public func removeOrphanedStudyBundles() throws {
        let fm = FileManager.default // swiftlint:disable:this identifier_name
        let allStudyEnrollments = self.studyEnrollments
        let allStudyBundleUrls = (try? fm.contents(of: Self.studyBundlesDirectory)) ?? []
        let orphanedBundleUrls = allStudyBundleUrls.filter { url in
            !allStudyEnrollments.contains { $0.studyBundleUrl.resolvingSymlinksInPath() == url.resolvingSymlinksInPath() }
        }
        guard !orphanedBundleUrls.isEmpty else {
            return // nothing to do
        }
        logger.notice("Found \(orphanedBundleUrls.count) orphaned study bundle(s). Will remove.")
        for url in orphanedBundleUrls {
            try fm.removeItem(at: url)
        }
    }
}


extension StudyManager {
    private func handleLocaleUpdate() {
        try? registerStudyTasksWithScheduler(for: studyEnrollments)
    }
}


extension StudyManager {
    /// Informs the Study Manager about current study definitions.
    ///
    /// Ths study manager will use these definitions to determine whether it needs to update any of the study participation contexts ic currently manages.
    public func informAboutStudies(_ studyBundles: some Collection<StudyBundle>) async throws {
        for studyBundle in studyBundles {
            let studyId = studyBundle.studyDefinition.id
            let studyRevision = studyBundle.studyDefinition.studyRevision
            for enrollment in try modelContext.fetch(FetchDescriptor(predicate: #Predicate<StudyEnrollment> {
                $0.studyId == studyId && $0.studyRevision < studyRevision
            })) {
                try enrollment.updateStudyBundle(studyBundle)
                try registerStudyTasksWithScheduler(for: CollectionOfOne(enrollment))
                try await setupStudyBackgroundComponents(for: CollectionOfOne(enrollment))
            }
        }
    }
}


// MARK: Event-Based Scheduling

extension StudyManager {
    private func handleStudyLifecycleEvent(_ event: StudyLifecycleEvent, for studyBundle: StudyBundle, at date: Date) {
        logger.notice(
            "Handling study lifecycle event '\(String(describing: event))' for study \(studyBundle.id) (\(studyBundle.studyDefinition.metadata.title))"
        )
        let cal = preferredLocale.calendar
        for enrollment in studyEnrollments where enrollment.studyId == studyBundle.id {
            guard let studyBundle = enrollment.studyBundle else {
                continue
            }
            for schedule in studyBundle.studyDefinition.componentSchedules {
                switch schedule.scheduleDefinition {
                case .repeated, .once(.date):
                    continue
                case let .once(.event(lifecycleEvent, offsetInDays, time)):
                    guard lifecycleEvent == event else {
                        logger.error(
                            "Skipping \(schedule.scheduleDefinition) bc the events don't match up (\(event.debugDescription) vs \(lifecycleEvent.debugDescription))"
                        )
                        continue
                    }
                    guard let occurrenceDate = cal
                        .date(byAdding: .day, value: offsetInDays, to: date)
                        .flatMap({ date in
                            time.flatMap { cal.date(bySettingHour: $0.hour, minute: $0.minute, second: $0.second, of: date) } ?? date
                        }) else {
                        logger.error("Unable to compute occurrence date. Skipping \(schedule.scheduleDefinition)")
                        continue
                    }
                    do {
                        _ = try createOrUpdateTask(
                            componentSchedule: schedule,
                            enrollment: enrollment,
                            taskSchedule: .once(at: occurrenceDate)
                        )
                    } catch TaskCreationError.unableToFindComponent, TaskCreationError.componentNotEligibleForTaskCreation {
                        continue
                    } catch {
                        logger.error("Error creating task: \(error)")
                    }
                }
            }
        }
    }
}

// swiftlint:disable:this file_length
