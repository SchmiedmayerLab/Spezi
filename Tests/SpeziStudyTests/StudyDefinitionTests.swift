//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import class ModelsR4.Questionnaire
@testable import SpeziStudyDefinition
import Testing


struct StudyDefinitionTests {
    @Test
    func testStudyEncodingAndDecoding() throws { // swiftlint:disable:this function_body_length
        let article1ComponentId = UUID()
        let article2ComponentId = UUID()
        let questionnaireComponentId = UUID()
        let testStudy = StudyDefinition(
            studyRevision: 0,
            metadata: StudyDefinition.Metadata(
                id: UUID(),
                title: "Test Study",
                explanationText: "This is our TestStudy",
                shortExplanationText: "This is our TestStudy",
                participationCriteria: StudyDefinition.ParticipationCriteria(
                    criterion: .ageAtLeast(18) && !.ageAtLeast(60) && (.isFromRegion(.unitedStates) || .isFromRegion(.unitedKingdom)) && .speaksLanguage(.english)
                    // swiftlint:disable:previous line_length
                ),
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
        
        let data = try JSONEncoder().encode(testStudy)
        let decodedStudy = try JSONDecoder().decode(StudyDefinition.self, from: data, configuration: .init(allowTrivialSchemaMigrations: true))
        #expect(decodedStudy == testStudy)
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
