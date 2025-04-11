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
import SpeziScheduler
import SpeziSchedulerUI
@_exported import SpeziStudyDefinition
import SwiftData
import SwiftUI


/// Manages enrollment and participation in studies.
///
/// ## Usage
///
/// Your app uses a single
///
/// ## Topics
///
/// ### Initialization
/// - ``init()``
/// - ``init(persistence:)``
///
/// ### Study Enrollment
/// - ``enroll(in:)``
/// - ``unenroll(from:)``
/// - ``informAboutStudies(_:)``
/// - ``StudyEnrollment``
/// - ``StudyEnrollmentError``
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
    
    /// The prefix used for SpeziScheduler Tasks created for study component schedules.
    private static let speziStudyDomainTaskIdPrefix = "edu.stanford.spezi.SpeziStudy.studyComponentTask."
    
    // swiftlint:disable attributes
    @Dependency(HealthKit.self) var healthKit
    @Dependency(Scheduler.self) var scheduler
    @Application(\.logger) var logger
    // swiftlint:enable attributes
    
    #if targetEnvironment(simulator)
    private var autosaveTask: _Concurrency.Task<Void, Never>?
    #endif
    
    let modelContainer: ModelContainer
    
    var modelContext: ModelContext {
        modelContainer.mainContext
    }
    
    /// All ``StudyEnrollment``s currently registered with the ``StudyManager``.
    public var studyEnrollments: [StudyEnrollment] {
        (try? modelContext.fetch(FetchDescriptor<StudyEnrollment>())) ?? []
    }
    
    /// Creates a new Study Manager.
    public nonisolated convenience init() {
        self.init(persistence: .onDisk)
    }
    
    /// Creates a new Study Manager, using the specified persistence configuration
    public nonisolated init(persistence: PersistenceConfiguration) {
        modelContainer = { () -> ModelContainer in
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
    public func configure() {
        _Concurrency.Task { @MainActor in
            let enrollments = try modelContext.fetch(FetchDescriptor<StudyEnrollment>())
            try registerStudyTasksWithScheduler(enrollments)
            try await setupStudyBackgroundComponents(enrollments)
            try removeOrphanedTasks()
            #if targetEnvironment(simulator)
            guard autosaveTask == nil else {
                return
            }
            autosaveTask = _Concurrency.Task.detached {
                while true {
                    await MainActor.run {
                        try? self.modelContext.save()
                    }
                    try? await _Concurrency.Task.sleep(for: .seconds(0.25))
                }
            }
            #endif
        }
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
    
    
    @MainActor // swiftlint:disable:next function_body_length
    private func registerStudyTasksWithScheduler(_ enrollments: some Collection<StudyEnrollment>) throws {
        for enrollment in enrollments {
            guard let study = enrollment.study else {
                continue
            }
            var createdTasks = Set<Task>()
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
                let category: Task.Category?
                let action: ScheduledTaskAction?
                switch component {
                case .questionnaire(let component):
                    category = .questionnaire
                    action = .answerQuestionnaire(component.questionnaire, enrollmentId: enrollment.persistentModelID)
                case .informational(let component):
                    category = .informational
                    action = .presentInformationalStudyComponent(component)
                case .healthDataCollection:
                    continue
                }
                let task = try scheduler.createOrUpdateTask(
                    id: taskId(for: component, in: study),
                    title: component.displayTitle.map { "\($0)" } ?? "",
                    instructions: "",
                    category: category,
                    schedule: .init(schedule.scheduleDefinition, participationStartDate: enrollment.enrollmentDate),
                    completionPolicy: schedule.completionPolicy,
                    // not passing true here currently, since that sometimes leads to SwiftData crashes (for some inputs)
                    scheduleNotifications: false,
                    notificationThread: NotificationThread.none,
                    tags: nil,
                    effectiveFrom: .now,
                    shadowedOutcomesHandling: .delete,
                    with: { context in
                        context.studyScheduledTaskAction = action
                    }
                ).task
                createdTasks.insert(task)
            }
            
            let activeTaskIds = createdTasks.mapIntoSet(\.id)
            let prefix = taskIdPrefix(for: study)
            let orphanedTasks = (try? scheduler.queryTasks(for: Date.distantPast...Date.distantFuture, predicate: #Predicate<Task> {
                // we filter for all tasks that are part of this study (determined based on prefix),
                // and are not among the tasks we just scheduled.
                // any task that exists in the scheduler and does not fulfill these criteria is a task that must have been scheduled
                // for a previous revision of the study, and belongs to a component that no longer exists
                $0.id.starts(with: prefix) && !activeTaskIds.contains($0.id)
            })) ?? []
            for orphanedTask in orphanedTasks {
                try scheduler.deleteAllVersions(of: orphanedTask)
            }
        }
    }
    
    @MainActor
    private func setupStudyBackgroundComponents(_ enrollments: some Collection<StudyEnrollment>) async throws {
        for enrollment in enrollments {
            guard let study = enrollment.study else {
                continue
            }
            for component in study.healthDataCollectionComponents {
                func setupSampleCollection(_ sampleTypes: some Collection<SampleType<some Any>>) async {
                    for sampleType in sampleTypes {
                        await healthKit.addHealthDataCollector(CollectSample(
                            sampleType,
                            start: .automatic,
                            continueInBackground: true
                        ))
                    }
                }
                await setupSampleCollection(component.sampleTypes.quantityTypes)
                await setupSampleCollection(component.sampleTypes.correlationTypes.flatMap(\.associatedQuantityTypes))
                await setupSampleCollection(component.sampleTypes.categoryTypes)
            }
        }
        // we want to request HealthKit auth once, at the end, for everything we just registered.
        try await healthKit.askForAuthorization()
    }
    
    
    private func taskIdPrefix(for study: StudyDefinition) -> String {
        taskIdPrefix(forStudyId: study.id)
    }
    
    private func taskIdPrefix(forStudyId studyId: StudyDefinition.ID) -> String {
        Self.speziStudyDomainTaskIdPrefix + studyId.uuidString
    }
    
    private func taskId(for component: StudyDefinition.Component, in study: StudyDefinition) -> String {
        "\(taskIdPrefix(for: study)).\(component.id)"
    }
    
    // MARK: Study Enrollment
    
    /// Enroll in a study.
    ///
    /// Once the device is enrolled into a study at revision `X`, subsequent ``enroll(in:)`` calls for the same study, with revision `Y`, will:
    /// - if `X = Y`: have no effect;
    /// - if `X < Y`: update the study enrollment, as if ``informAboutStudies(_:)`` was called with the new study revision;
    /// - if `X > Y`: throw an error.
    @MainActor
    public func enroll(in study: StudyDefinition) async throws {
        // big issue in this function is that, if we throw somewhere we kinda need to unroll _all_ the changes we've made so far
        // (which is much easier said than done...)
        let enrollments = try modelContext.fetch(FetchDescriptor<StudyEnrollment>())
        
        if case let existingEnrollments = enrollments.filter({ $0.studyId == study.id }),
           !existingEnrollments.isEmpty {
            // There exists at least one enrollment for this study
            if let enrollment = existingEnrollments.first, existingEnrollments.count == 1 {
                if enrollment.studyRevision == study.studyRevision {
                    // already enrolled in this study, at this revision.
                    // this is a no-op.
                    return
                } else if enrollment.studyRevision < study.studyRevision {
                    // if we have only one enrollment, and it is for an older version of the study,
                    // we treat the enroll call as a study definition update
                    try await informAboutStudies(CollectionOfOne(study))
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
        
        let enrollment = try StudyEnrollment(enrollmentDate: .now, study: study)
        modelContext.insert(enrollment)
        try modelContext.save()
        try registerStudyTasksWithScheduler(CollectionOfOne(enrollment))
        try await setupStudyBackgroundComponents(CollectionOfOne(enrollment))
    }
    
    
    /// Unenroll from a study.
    public func unenroll(from enrollment: StudyEnrollment) throws {
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
        modelContext.delete(enrollment)
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
}


extension StudyManager {
    /// Informs the Study Manager about current study definitions.
    ///
    /// Ths study manager will use these definitions to determine whether it needs to update any of the study participation contexts ic currently manages.
    public func informAboutStudies(_ studies: some Collection<StudyDefinition>) async throws {
        for study in studies {
            let studyId = study.id
            let studyRevision = study.studyRevision
            for enrollment in try modelContext.fetch(FetchDescriptor(predicate: #Predicate<StudyEnrollment> {
                $0.studyId == studyId && $0.studyRevision < studyRevision
            })) {
                try enrollment.updateStudyDefinition(study)
                try registerStudyTasksWithScheduler(CollectionOfOne(enrollment))
                try await setupStudyBackgroundComponents(CollectionOfOne(enrollment))
            }
        }
    }
}
