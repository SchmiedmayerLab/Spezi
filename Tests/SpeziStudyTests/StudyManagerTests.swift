//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

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
    private static let articleComponentId = UUID()
    
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
                    id: Self.articleComponentId,
                    fileRef: .init(category: .informationalArticle, filename: "a1", fileExtension: "md")
                ))
            ],
            componentSchedules: [
                .init(
                    id: UUID(),
                    componentId: Self.articleComponentId,
                    scheduleDefinition: .repeated(.daily(hour: 1, minute: 0)),
                    completionPolicy: .afterStart,
                    notifications: .enabled(thread: .custom("Articles"))
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
        try #expect(studyManager.scheduler.queryTasks(for: allTime).count == 1)
        studyManager.modelContext.delete(enrollment)
        try #expect(studyManager.scheduler.queryTasks(for: allTime).count == 1)
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
        #expect(LocalizationKey(language: .english, region: .unitedStates).score(against: .init(identifier: "en_US"), using: .default) == 1)
        #expect(LocalizationKey(language: .spanish, region: .unitedStates).score(against: .init(identifier: "es_US"), using: .default) == 1)
        #expect(LocalizationKey(language: .german, region: .unitedStates).score(against: .init(identifier: "es_US"), using: .default) == 0.75)
    }
    
    
    /// Tests that the StudyManager properly updates itself when the preferred locale changes.
    @Test
    func localeUpdate() async throws {
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
            #expect(tasks.count == 1)
            let task = try #require(tasks.first)
            #expect(String(localized: task.title) == "Welcome to our Study!")
        }
        studyManager.preferredLocale = localeEsUS
        do {
            let tasks = try scheduler.queryAllTasks()
            #expect(tasks.count == 2)
            #expect(tasks.mapIntoSet(\.id).count == 1)
            let task = try #require(tasks.first).latestVersion
            #expect(String(localized: task.title) == "Bienvenido a nuestro estudio!")
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
    
    
    deinit {
        try? FileManager.default.removeItem(at: studyBundle.bundleUrl)
        try? FileManager.default.removeItem(at: StudyManager.studyBundlesDirectory)
    }
}
