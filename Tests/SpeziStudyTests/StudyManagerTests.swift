//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable type_body_length multiline_function_chains

import Foundation
import Spezi
import SpeziHealthKit
import SpeziLocalization
@_spi(TestingSupport)
import SpeziScheduler
@_spi(TestingSupport)
@testable import SpeziStudy
@testable import SpeziStudyDefinition
import SpeziTesting
import Testing


private actor TestStandard: Standard, HealthKitConstraint {
    func handleNewSamples<Sample>(_ addedSamples: some Collection<Sample>, ofType sampleType: SampleType<Sample>) async {
        // ...
    }
    
    func handleDeletedObjects<Sample>(_ deletedObjects: some Collection<HKDeletedObject>, ofType sampleType: SampleType<Sample>) async {
        // ...
    }
}


@Suite
@MainActor
final class StudyManagerTests {
    private static let welcomeArticleComponentId = UUID()
    private static let sixMinuteWalkTestComponentId = UUID()
    private static let twelveMinuteRunTestComponentId = UUID()
    
    private let studyBundle: StudyBundle
    
    init() throws { // swiftlint:disable:this function_body_length
        let testStudy = StudyDefinition(
            studyRevision: 0,
            metadata: .init(
                id: UUID(),
                title: "",
                explanationText: "",
                shortExplanationText: "",
                participationCriterion: true,
                enrollmentConditions: .none
            ),
            components: [
                .informational(.init(
                    id: Self.welcomeArticleComponentId,
                    fileRef: .init(category: .informationalArticle, filename: "a1", fileExtension: "md")
                )),
                .timedWalkingTest(.init(
                    id: Self.sixMinuteWalkTestComponentId,
                    test: .sixMinuteWalkTest
                )),
                .timedWalkingTest(.init(
                    id: Self.twelveMinuteRunTestComponentId,
                    test: .twelveMinuteRunTest
                ))
            ],
            componentSchedules: [
                .init(
                    id: UUID(),
                    componentId: Self.welcomeArticleComponentId,
                    scheduleDefinition: .once(.event(.enrollment)),
                    completionPolicy: .afterStart,
                    notifications: .disabled
                ),
                .init(
                    id: UUID(),
                    componentId: Self.sixMinuteWalkTestComponentId,
                    scheduleDefinition: .repeated(.daily(interval: 2, hour: 0, minute: 0)),
                    completionPolicy: .afterStart,
                    notifications: .disabled
                ),
                .init(
                    id: UUID(),
                    componentId: Self.twelveMinuteRunTestComponentId,
                    scheduleDefinition: .repeated(.daily(interval: 2, hour: 0, minute: 0), offset: .init(day: 1)),
                    completionPolicy: .afterStart,
                    notifications: .disabled
                )
            ]
        )
        let tmpUrl = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, conformingTo: .speziStudyBundle)
        studyBundle = try StudyBundle.writeToDisk(
            at: tmpUrl,
            definition: testStudy,
            files: [
                StudyBundle.FileInput(
                    fileRef: .init(category: .informationalArticle, filename: "a1", fileExtension: "md"),
                    localization: .init(language: .english, region: .unitedStates),
                    contents: """
                        ---
                        title: Welcome to our Study!
                        ---
                        """
                ),
                StudyBundle.FileInput(
                    fileRef: .init(category: .informationalArticle, filename: "a1", fileExtension: "md"),
                    localization: .init(language: .spanish, region: .unitedStates),
                    contents: """
                        ---
                        title: Bienvenido a nuestro estudio!
                        ---
                        """
                )
            ]
        )
    }
    
    
    @Test
    func enrollment() async throws {
        let cal = Calendar.current
        let scheduler = Scheduler(persistence: .inMemory)
        let studyManager = StudyManager(persistence: .inMemory)
        withDependencyResolution(standard: TestStandard()) {
            scheduler
            studyManager
        }
        let next4Weeks = try cal.startOfDay(for: .now)..<#require(cal.date(byAdding: .weekOfYear, value: 4, to: cal.startOfDay(for: .now)))
        #expect(try scheduler.queryAllTasks().isEmpty)
        #expect(try scheduler.queryEvents(for: next4Weeks).isEmpty)
        
        try await studyManager.enroll(in: studyBundle)
        
        #expect(studyManager.studyEnrollments.count == 1)
        let enrollment = try #require(studyManager.studyEnrollments.first)
        #expect(enrollment.studyId == studyBundle.id)
        #expect(enrollment.studyId == studyBundle.studyDefinition.id)
        #expect(try #require(enrollment.studyBundle).studyDefinition == studyBundle.studyDefinition)
        
        #expect(try scheduler.queryAllTasks().count == 3)
        #expect(try scheduler.queryEvents(for: cal.rangeOfDay(for: .now)).mapIntoSet { String(localized: $0.task.title) } == [
            "Welcome to our Study!", "Six-Minute Walk Test"
        ])
        #expect(try scheduler.queryEvents(for: cal.startOfNextDay(for: .now)..<cal.startOfNextDay(for: cal.startOfNextDay(for: .now))).mapIntoSet {
            String(localized: $0.task.title)
        } == ["12-Minute Run Test"])
    }
    
    
    @Test
    func retroactiveEnrollment() async throws {
        let cal = Calendar.current
        let scheduler = Scheduler(persistence: .inMemory)
        let studyManager = StudyManager(persistence: .inMemory)
        withDependencyResolution(standard: TestStandard()) {
            scheduler
            studyManager
        }
        let next4Weeks = try cal.startOfDay(for: .now)..<#require(cal.date(byAdding: .weekOfYear, value: 4, to: cal.startOfDay(for: .now)))
        #expect(try scheduler.queryAllTasks().isEmpty)
        #expect(try scheduler.queryEvents(for: next4Weeks).isEmpty)
        
        try await studyManager.enroll(in: studyBundle, enrollmentDate: cal.startOfPrevDay(for: .now))
        #expect(studyManager.studyEnrollments.count == 1)
        let enrollment = try #require(studyManager.studyEnrollments.first)
        #expect(enrollment.studyId == studyBundle.id)
        #expect(enrollment.studyId == studyBundle.studyDefinition.id)
        #expect(try #require(enrollment.studyBundle).studyDefinition == studyBundle.studyDefinition)
        #expect(try scheduler.queryAllTasks().count == 2)
        #expect(try scheduler.queryEvents(for: cal.rangeOfDay(for: .now)).mapIntoSet { String(localized: $0.task.title) } == [
            "12-Minute Run Test"
        ])
        #expect(try scheduler.queryEvents(for: cal.startOfNextDay(for: .now)..<cal.startOfNextDay(for: cal.startOfNextDay(for: .now))).mapIntoSet {
            String(localized: $0.task.title)
        } == ["Six-Minute Walk Test"])
    }
    
    
    @Test
    func orphanTaskHandling() async throws {
        let allTime = Date.distantPast...Date.distantFuture
        let studyManager = StudyManager(persistence: .inMemory)
        withDependencyResolution(standard: TestStandard()) {
            Scheduler(persistence: .inMemory)
            studyManager
        }
        try await studyManager.enroll(in: studyBundle)
        
        #expect(studyManager.studyEnrollments.count == 1)
        let enrollment = try #require(studyManager.studyEnrollments.first)
        #expect(enrollment.studyId == studyBundle.id)
        #expect(enrollment.studyId == studyBundle.studyDefinition.id)
        #expect(try #require(enrollment.studyBundle).studyDefinition == studyBundle.studyDefinition)
        try #expect(studyManager.scheduler.queryTasks(for: allTime).count == 3)
        studyManager.modelContext.delete(enrollment)
        try #expect(studyManager.scheduler.queryTasks(for: allTime).count == 3)
        try studyManager.removeOrphanedTasks()
        
        try await _Concurrency.Task.sleep(for: .seconds(0.2))
        try #expect(studyManager.scheduler.queryTasks(for: allTime).isEmpty)
    }
    
    
    @Test
    func orphanStudyBundleHandling() async throws {
        let fileManager = FileManager.default
        let studyManager = StudyManager(persistence: .inMemory)
        withDependencyResolution(standard: TestStandard()) {
            Scheduler(persistence: .inMemory)
            studyManager
        }
        try await studyManager.enroll(in: studyBundle)
        
        #expect(studyManager.studyEnrollments.count == 1)
        let enrollment = try #require(studyManager.studyEnrollments.first)
        #expect(enrollment.studyId == studyBundle.id)
        #expect(enrollment.studyId == studyBundle.studyDefinition.id)
        #expect(try #require(enrollment.studyBundle).studyDefinition == studyBundle.studyDefinition)
        #expect(try fileManager.contents(of: StudyManager.studyBundlesDirectory).contains(enrollment.studyBundleUrl))
        studyManager.modelContext.delete(enrollment)
        #expect(try fileManager.contents(of: StudyManager.studyBundlesDirectory).contains(enrollment.studyBundleUrl))
        try studyManager.removeOrphanedTasks() // not what we're testing but important to ensure that the test doesn't crash
        try studyManager.removeOrphanedStudyBundles()
        #expect(try !fileManager.contents(of: StudyManager.studyBundlesDirectory).contains(enrollment.studyBundleUrl))
    }
    
    
    @Test
    func localeMatching() throws {
        #expect(LocalizationKey(language: .english, region: .unitedStates).score(against: Locale(identifier: "en_US"), using: .default) == 1)
        #expect(LocalizationKey(language: .spanish, region: .unitedStates).score(against: Locale(identifier: "es_US"), using: .default) == 1)
        #expect(LocalizationKey(language: .german, region: .unitedStates).score(against: Locale(identifier: "es_US"), using: .default) == 0.75)
    }
    
    
    /// Tests that the StudyManager properly updates itself when the preferred locale changes.
    @Test
    func localeUpdate() async throws {
        let cal = Calendar.current
        let localeEnUS = Locale(identifier: "en_US")
        let localeEsUS = Locale(identifier: "es_US")
        let studyManager = StudyManager(preferredLocale: localeEnUS, persistence: .inMemory)
        let scheduler = Scheduler(persistence: .inMemory)
        withDependencyResolution(standard: TestStandard()) {
            scheduler
            studyManager
        }
        try await studyManager.enroll(in: studyBundle)
        #expect(studyManager.studyEnrollments.count == 1)
        let enrollment = try #require(studyManager.studyEnrollments.first)
        
        do {
            let tasks = try scheduler.queryAllTasks()
            #expect(tasks.count == 3)
            #expect(tasks.mapIntoSet { String(localized: $0.title) } == [
                "Welcome to our Study!", "Six-Minute Walk Test", "12-Minute Run Test"
            ])
        }
        studyManager.preferredLocale = localeEsUS
        do {
            let tasks = try scheduler.queryAllTasks()
            #expect(tasks.count == 6) // it's doubled bc we now have a new version of every task
            #expect(tasks.mapIntoSet(\.id).count == 3)
            #expect(tasks.mapIntoSet { String(localized: $0.latestVersion.title) }.contains("Bienvenido a nuestro estudio!"))
            // ^ intentionally only looking for the article title, since the other 2 (timed walk test names) are still english; this is a known bug
        }
        let nextYear = try cal.startOfDay(for: .now)..<#require(cal.date(byAdding: .year, value: 1, to: cal.startOfDay(for: .now)))
        do {
            let welcomeEvents = try scheduler.queryEvents(for: nextYear).filter {
                $0.task.id.contains(Self.welcomeArticleComponentId.uuidString)
            }
            #expect(welcomeEvents.count == 1)
            #expect(try !#require(welcomeEvents.first).isCompleted)
            try #require(welcomeEvents.first).complete()
            try await _Concurrency.Task.sleep(for: .seconds(0.2))
            #expect(try scheduler.queryEvents(for: nextYear).filter {
                $0.task.id.contains(Self.welcomeArticleComponentId.uuidString)
            }.count { !$0.isCompleted } == 0)
        }
        studyManager.preferredLocale = localeEnUS
        do {
            let welcomeEvents = try scheduler.queryEvents(for: nextYear).filter {
                $0.task.id.contains(Self.welcomeArticleComponentId.uuidString)
            }
            #expect(welcomeEvents.count { $0.isCompleted } == 1)
            #expect(welcomeEvents.count { !$0.isCompleted } == 0)
        }
        try studyManager.unenroll(from: enrollment)
    }
    
    
    @Test
    func localeUtils() {
        let locale1 = Locale(language: .english, region: .germany)
        #expect(locale1.language == .english)
        #expect(locale1.region == .germany)
        
        let locale2 = Locale(language: .spanish, region: .antarctica)
        #expect(locale2.language == .spanish)
        #expect(locale2.region == .antarctica)
    }
    
    
    @Test
    func schedules() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US")
        cal.timeZone = .losAngeles
        let enrollmentDate = try #require(cal.date(from: .init(year: 2025, month: 7, day: 31)))
        #expect(cal.component(.weekday, from: enrollmentDate) == 5)
        
        let schedule1: Schedule = .fromRepeated(
            .repeated(.daily(hour: 0, minute: 0)),
            in: cal,
            participationStartDate: enrollmentDate
        )
        let schedule2: Schedule = .fromRepeated(
            .repeated(.weekly(weekday: nil, hour: 0, minute: 0)),
            in: cal,
            participationStartDate: enrollmentDate
        )
        let schedule3: Schedule = .fromRepeated(
            .repeated(.weekly(weekday: .wednesday, hour: 0, minute: 0)),
            in: cal,
            participationStartDate: enrollmentDate
        )
        let schedule4: Schedule = .fromRepeated(
            .repeated(.monthly(day: nil, hour: 0, minute: 0)),
            in: cal,
            participationStartDate: enrollmentDate
        )
        let schedule5: Schedule = .fromRepeated(
            .repeated(.monthly(day: 2, hour: 0, minute: 0)),
            in: cal,
            participationStartDate: enrollmentDate
        )
        let nextOccurrence = { (schedule: Schedule) -> Date? in
            schedule.occurrences(in: enrollmentDate.addingTimeInterval(1)..<Date.distantFuture).first { _ in true }?.start
        }
        #expect(try #require(nextOccurrence(schedule1)) == #require(cal.date(from: .init(year: 2025, month: 8, day: 1))))
        #expect(try #require(nextOccurrence(schedule2)) == #require(cal.date(from: .init(year: 2025, month: 8, day: 7))))
        #expect(try #require(nextOccurrence(schedule3)) == #require(cal.date(from: .init(year: 2025, month: 8, day: 6))))
        #expect(try #require(nextOccurrence(schedule4)) == #require(cal.date(from: .init(year: 2025, month: 8, day: 31))))
        #expect(try #require(nextOccurrence(schedule5)) == #require(cal.date(from: .init(year: 2025, month: 8, day: 2))))
    }
    
    
    deinit {
        try? FileManager.default.removeItem(at: studyBundle.bundleUrl)
        try? FileManager.default.removeItem(at: StudyManager.studyBundlesDirectory)
    }
}
