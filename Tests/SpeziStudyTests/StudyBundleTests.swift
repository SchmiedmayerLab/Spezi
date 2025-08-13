//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable type_contents_order

import Foundation
import class ModelsR4.Questionnaire
import SpeziFoundation
import SpeziHealthKit
import SpeziHealthKitBulkExport
@testable import SpeziStudyDefinition
import Testing


@Suite
struct StudyBundleTests {
    static let locale = Locale(identifier: "en_US")
    
    @Test
    func displayTitles() throws {
        let bundle = try Self.testStudyBundle
        let components = bundle.studyDefinition.components
        let expectedNames: [String?] = [
            "Informational Component #1",
            "Informational Component #2",
            "Social Support",
            nil, // health collection
            "Six-Minute Walk Test",
            "12-Minute Run Test",
            "8.5-Minute Walk Test"
        ]
        #expect(components.count == expectedNames.count)
        for (component, expectedName) in zip(components, expectedNames) {
            #expect(bundle.displayTitle(for: component, in: Self.locale) == expectedName)
        }
    }
    
    @Test
    func bundleEquality() throws {
        let bundle1 = try Self.testStudyBundle
        let bundle2 = try Self.testStudyBundle
        #expect(bundle1 == bundle2)
        let bundle3Url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, conformingTo: .speziStudyBundle)
        try bundle1.copy(to: bundle3Url)
        let bundle3 = try StudyBundle(bundleUrl: bundle3Url)
        #expect(bundle3 != bundle1)
        #expect(bundle3 != bundle2)
    }
    
    @Test
    func filenameLocalizationParsing() throws {
        typealias LocalizedFileRef = StudyBundle.LocalizedFileReference
        #expect(StudyBundle.parse(filename: "Welcome+en-US.md", in: .consent) == LocalizedFileRef(
            fileRef: .init(category: .consent, filename: "Welcome", fileExtension: "md"),
            localization: .init(language: .english, region: .unitedStates)
        ))
        #expect(StudyBundle.parse(filename: "Welcome+es-US.md", in: .consent) == LocalizedFileRef(
            fileRef: .init(category: .consent, filename: "Welcome", fileExtension: "md"),
            localization: .init(language: .spanish, region: .unitedStates)
        ))
        #expect(StudyBundle.parse(filename: "Welcome+en_US.md", in: .consent) == nil)
        #expect(StudyBundle.parse(filename: "Welcome.md", in: .consent) == nil)
        #expect(StudyBundle.parse(filename: "Welcome+de-US.md", in: .consent) == LocalizedFileRef(
            fileRef: .init(category: .consent, filename: "Welcome", fileExtension: "md"),
            localization: .init(language: .german, region: .unitedStates)
        ))
        #expect(StudyBundle.parse(filename: "Welcome+en-DE.md", in: .consent) == LocalizedFileRef(
            fileRef: .init(category: .consent, filename: "Welcome", fileExtension: "md"),
            localization: .init(language: .english, region: .germany)
        ))
        #expect(StudyBundle.parse(filename: "Welcome+de-DE.md", in: .consent) == LocalizedFileRef(
            fileRef: .init(category: .consent, filename: "Welcome", fileExtension: "md"),
            localization: .init(language: .german, region: .germany)
        ))
        #expect(StudyBundle.parse(filename: "Welcome+en-GB.md", in: .consent) == LocalizedFileRef(
            fileRef: .init(category: .consent, filename: "Welcome", fileExtension: "md"),
            localization: .init(language: .english, region: .unitedKingdom)
        ))
    }
    
    @Test
    func resourceFetching() throws {
        let studyBundle = try Self.testStudyBundle
        #expect(try studyBundle.consentText(
            for: .init(category: .consent, filename: "Consent", fileExtension: "md"),
            in: Self.locale
        ) == "---\ntitle: Study Consent\n---\n\n# Consent")
    }
    
    
// MARK: Test Study
    
    static var testStudyBundle: StudyBundle {
        get throws {
            try _testStudyBundle.get()
        }
    }

    private static let _testStudyBundle: Result<StudyBundle, any Error> = .init { // swiftlint:disable:this closure_body_length
        // swiftlint:disable force_unwrapping
        let studyId = UUID(uuidString: "1E82CA84-E031-43C1-9CA4-9F68B5F246B8")!
        let article1ComponentId = UUID(uuidString: "F924B17E-F45C-40D8-8B8A-C694C6D4956D")!
        let article2ComponentId = UUID(uuidString: "6BE663DB-912F-4F4E-BD62-D743A9FB8941")!
        let questionnaireComponentId = UUID(uuidString: "7E3CD36F-26CD-418B-9CAD-CFB268070162")!
        let healthDataCollectionComponentId = UUID(uuidString: "A52CBB75-6F9D-4B59-BA86-01532EFE41D2")!
        let timedWalkingTest1ComponentId = UUID(uuidString: "581E8C1F-C26C-4884-9536-6360712CD50A")!
        let timedWalkingTest2ComponentId = UUID(uuidString: "CDC1643B-E868-43DE-A091-25CC62DE3F17")!
        let timedWalkingTest3ComponentId = UUID(uuidString: "37FFF91E-E490-49D4-9A93-0B94D9C3DC02")!
        let schedule1Id = UUID(uuidString: "92E77E46-4135-41B4-BE23-59AD233C4C79")!
        let schedule2Id = UUID(uuidString: "D7263B0D-29BB-42BB-BF92-FE4DBC170281")!
        let schedule3Id = UUID(uuidString: "B73A310D-692A-4C9F-9FA5-897FDAEAC796")!
        // swiftlint:enable force_unwrapping
        let definition = StudyDefinition(
            studyRevision: 0,
            metadata: StudyDefinition.Metadata(
                id: studyId,
                title: "Test Study",
                explanationText: "This is our TestStudy",
                shortExplanationText: "This is our TestStudy",
                participationCriterion: .ageAtLeast(18) && !.ageAtLeast(60) && (.isFromRegion(.unitedStates) || .isFromRegion(.unitedKingdom)) && .speaksLanguage(.english),
                // swiftlint:disable:previous line_length
                enrollmentConditions: .requiresInvitation(verificationEndpoint: try #require(URL(string: "https://mhc.stanford.edu/api/enroll"))),
                consentFileRef: .init(category: .consent, filename: "Consent", fileExtension: "md")
            ),
            components: [
                .informational(.init(
                    id: article1ComponentId,
                    fileRef: .init(category: .informationalArticle, filename: "Info1", fileExtension: "md")
                )),
                .informational(.init(
                    id: article2ComponentId,
                    fileRef: .init(category: .informationalArticle, filename: "Info2", fileExtension: "md")
                )),
                .questionnaire(.init(
                    id: questionnaireComponentId,
                    fileRef: .init(category: .questionnaire, filename: "SocialSupportQuestionnaire", fileExtension: "json")
                )),
                .healthDataCollection(.init(
                    id: healthDataCollectionComponentId,
                    sampleTypes: [SampleType.heartRate, SampleType.stepCount, SampleType.sleepAnalysis],
                    historicalDataCollection: .enabled(.last(DateComponents(year: 7, month: 6)))
                )),
                .timedWalkingTest(.init(
                    id: timedWalkingTest1ComponentId,
                    test: .init(duration: .minutes(6), kind: .walking)
                )),
                .timedWalkingTest(.init(
                    id: timedWalkingTest2ComponentId,
                    test: .init(duration: .minutes(12), kind: .running)
                )),
                .timedWalkingTest(.init(
                    id: timedWalkingTest3ComponentId,
                    test: .init(duration: .seconds(510), kind: .walking)
                ))
            ],
            componentSchedules: [
                .init(
                    id: schedule1Id,
                    componentId: article1ComponentId,
                    scheduleDefinition: .repeated(.daily(hour: 11, minute: 21), offset: .init(day: 4)),
                    completionPolicy: .afterStart,
                    notifications: .enabled(thread: .none)
                ),
                .init(
                    id: schedule2Id,
                    componentId: article2ComponentId,
                    scheduleDefinition: .repeated(.daily(interval: 2, hour: 17, minute: 41)),
                    completionPolicy: .anytime,
                    notifications: .enabled(thread: .global)
                ),
                .init(
                    id: schedule3Id,
                    componentId: questionnaireComponentId,
                    scheduleDefinition: .repeated(.weekly(weekday: .wednesday, hour: 21, minute: 59), offset: .init(day: 1)),
                    completionPolicy: .sameDayAfterStart,
                    notifications: .enabled(thread: .task)
                )
            ]
        )
        let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, conformingTo: .speziStudyBundle)
        return try StudyBundle.writeToDisk(at: url, definition: definition, files: [
            StudyBundle.FileInput(
                fileRef: .init(category: .consent, filename: "Consent", fileExtension: "md"),
                localization: .init(locale: locale),
                contents: """
                    ---
                    title: Study Consent
                    ---
                    
                    # Consent
                    """
            ),
            StudyBundle.FileInput(
                fileRef: .init(category: .informationalArticle, filename: "Info1", fileExtension: "md"),
                localization: .init(locale: locale),
                contents: """
                    ---
                    title: Informational Component #1
                    headerImage: "Header1"
                    ---
                    
                    This is the text of the first informational component
                    """
            ),
            StudyBundle.FileInput(
                fileRef: .init(category: .informationalArticle, filename: "Info2", fileExtension: "md"),
                localization: .init(locale: locale),
                contents: """
                    ---
                    title: Informational Component #2
                    headerImage: "Header2"
                    ---
                    
                    This is the text of the second informational component
                    """
            ),
            StudyBundle.FileInput(
                fileRef: .init(category: .questionnaire, filename: "SocialSupportQuestionnaire", fileExtension: "json"),
                localization: .init(locale: locale),
                contents: try Questionnaire.named("SocialSupportQuestionnaire")
            )
        ])
    }
}
