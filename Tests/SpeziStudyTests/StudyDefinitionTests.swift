//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import class ModelsR4.Questionnaire
import SpeziFoundation
@testable import SpeziStudyDefinition
import Testing


struct StudyDefinitionTests {
    @Test
    func studyEncodingAndDecoding() throws {
        let data = try JSONEncoder().encode(testStudy)
        let decodedStudy = try JSONDecoder().decode(StudyDefinition.self, from: data, configuration: .init(allowTrivialSchemaMigrations: true))
        #expect(try decodedStudy == testStudy)
    }
    
    
    @Test
    func decodedStudyVersionExtraction() throws {
        let input1 = try JSONEncoder().encode(testStudy)
        #expect(try StudyDefinition.schemaVersion(of: input1, using: JSONDecoder()) == StudyDefinition.schemaVersion)
        
        let input2 = try #require(#"{"schemaVersion":"1.2.3", "glorb": "florb"}"#.data(using: .utf8))
        #expect(try StudyDefinition.schemaVersion(of: input2, using: JSONDecoder()) == Version(1, 2, 3))
    }
}


extension Locale.Language {
    static let english = Locale.Language(identifier: "en")
}


extension Questionnaire {
    static func named(_ name: String) throws -> Questionnaire {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw NSError(
                domain: "edu.stanford.spezi",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load data"]
            )
        }
        return try JSONDecoder().decode(Questionnaire.self, from: data)
    }
}


// MARK: Test Study

extension StudyDefinitionTests {
    var testStudy: StudyDefinition {
        get throws {
            // swiftlint:disable force_unwrapping
            let studyId = UUID(uuidString: "1E82CA84-E031-43C1-9CA4-9F68B5F246B8")!
            let article1ComponentId = UUID(uuidString: "F924B17E-F45C-40D8-8B8A-C694C6D4956D")!
            let article2ComponentId = UUID(uuidString: "6BE663DB-912F-4F4E-BD62-D743A9FB8941")!
            let questionnaireComponentId = UUID(uuidString: "7E3CD36F-26CD-418B-9CAD-CFB268070162")!
            // swiftlint:enable force_unwrapping
            return StudyDefinition(
                studyRevision: 0,
                metadata: StudyDefinition.Metadata(
                    id: studyId,
                    title: "Test Study",
                    explanationText: "This is our TestStudy",
                    shortExplanationText: "This is our TestStudy",
                    participationCriterion: .ageAtLeast(18) && !.ageAtLeast(60) && (.isFromRegion(.unitedStates) || .isFromRegion(.unitedKingdom)) && .speaksLanguage(.english),
                    // swiftlint:disable:previous line_length
                    enrollmentConditions: .requiresInvitation(verificationEndpoint: try #require(URL(string: "https://mhc.stanford.edu/api/enroll")))
                ),
                components: [
                    .informational(.init(
                        id: article1ComponentId,
                        title: "Informational Component #1",
                        headerImage: "Header1",
                        body: "This is the text of the first informational component"
                    )),
                    .informational(.init(
                        id: article2ComponentId,
                        title: "Informational Component #2",
                        headerImage: "Header2",
                        body: "This is the text of the second informational component"
                    )),
                    .questionnaire(.init(
                        id: questionnaireComponentId,
                        questionnaire: try .named("SocialSupportQuestionnaire")
                    ))
                ],
                componentSchedules: [
                    .init(
                        componentId: article1ComponentId,
                        scheduleDefinition: .repeated(.daily(hour: 11, minute: 21), startOffsetInDays: 4),
                        completionPolicy: .afterStart
                    ),
                    .init(
                        componentId: article2ComponentId,
                        scheduleDefinition: .repeated(.daily(interval: 2, hour: 17, minute: 41), startOffsetInDays: 0),
                        completionPolicy: .anytime
                    ),
                    .init(
                        componentId: questionnaireComponentId,
                        scheduleDefinition: .repeated(.weekly(weekday: .wednesday, hour: 21, minute: 59), startOffsetInDays: 1),
                        completionPolicy: .sameDayAfterStart
                    )
                ]
            )
        }
    }
}
