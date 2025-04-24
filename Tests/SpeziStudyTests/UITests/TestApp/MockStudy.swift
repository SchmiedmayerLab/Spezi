//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
import class ModelsR4.Questionnaire
import SpeziFoundation
import SpeziHealthKit
import SpeziStudyDefinition


extension UUID {
    // swiftlint:disable force_unwrapping
    fileprivate static let studyId = UUID(uuidString: "885099E4-6318-43CC-BFF1-7D7FAD1968F6")!
    fileprivate static let article1ComponentId = UUID(uuidString: "BFAF8AA3-211B-40AF-AE6F-3472DCEECFA8")!
    fileprivate static let article2ComponentId = UUID(uuidString: "C3651C0F-BF75-49FB-AB73-E8779746C621")!
    fileprivate static let questionnaireComponentId = UUID(uuidString: "898513A2-356A-4D45-AD41-81AED3CB18E8")!
    fileprivate static let healthComponentId = UUID(uuidString: "2B054B83-6165-4C45-AFA0-391701FD101B")!
    // swiftlint:enable force_unwrapping
}

extension Locale.Language {
    static let english = Locale.Language(identifier: "en")
}


enum MockStudyRevision: UInt {
    // swiftlint:disable identifier_name
    // base version of the study
    case v1 = 1
    // this version removes the questionnaire component, so that we can test the component removal logic
    case v2 = 2
    // this version adds a second article component, so that we can test the component addition logic
    case v3 = 3
    // swiftlint:enable identifier_name
}


func mockStudy(revision: MockStudyRevision) -> StudyDefinition { // swiftlint:disable:this function_body_length
    StudyDefinition(
        studyRevision: revision.rawValue,
        metadata: StudyDefinition.Metadata(
            id: .studyId,
            title: "TestStudy",
            explanationText: "This is a fake study, intended for testing the SpeziStudy package.",
            shortExplanationText: "SpeziStudy fake test study",
            participationCriterion: .ageAtLeast(18) && !.ageAtLeast(60) && (.isFromRegion(.unitedStates) || .isFromRegion(.unitedKingdom)) && .speaksLanguage(.english),
            // swiftlint:disable:previous line_length
            enrollmentConditions: .none
        ),
        components: Array { // swiftlint:disable:this closure_body_length
            StudyDefinition.Component.informational(.init(
                id: .article1ComponentId,
                title: "Article1 Title",
                headerImage: "",
                body: "Article1 Body"
            ))
            StudyDefinition.Component.healthDataCollection(.init(
                id: .healthComponentId,
                sampleTypes: SampleTypesCollection(
                    quantity: [.stepCount, .heartRate, .activeEnergyBurned],
                    correlation: [.bloodPressure],
                    category: [.sleepAnalysis]
                ),
                historicalDataCollection: .disabled
            ))
            switch revision {
            case .v1:
                StudyDefinition.Component.questionnaire(.init(
                    id: .questionnaireComponentId,
                    questionnaire: { () -> Questionnaire in
                        guard let url = Bundle.main.url(forResource: "SocialSupportQuestionnaire", withExtension: "json"),
                              let data = try? Data(contentsOf: url),
                              let questionnaire = try? JSONDecoder().decode(Questionnaire.self, from: data) else {
                            fatalError("Unable to load questionnaire")
                        }
                        return questionnaire
                    }()
                ))
            case .v2:
                let _ = () // swiftlint:disable:this redundant_discardable_let
            case .v3:
                StudyDefinition.Component.informational(.init(
                    id: .article2ComponentId,
                    title: "Article2 Title",
                    headerImage: "",
                    body: "Article2 Body"
                ))
            }
        },
        componentSchedules: Array {
            StudyDefinition.ComponentSchedule(
                componentId: .article1ComponentId,
                scheduleDefinition: .repeated(.weekly(weekday: .wednesday, hour: 09, minute: 00), startOffsetInDays: 0),
                completionPolicy: .anytime
            )
            switch revision {
            case .v1:
                StudyDefinition.ComponentSchedule(
                    componentId: .questionnaireComponentId,
                    scheduleDefinition: .repeated(.weekly(weekday: .monday, hour: 09, minute: 00), startOffsetInDays: 0),
                    completionPolicy: .afterStart
                )
            case .v2:
                let _ = () // swiftlint:disable:this redundant_discardable_let
            case .v3:
                StudyDefinition.ComponentSchedule(
                    componentId: .article2ComponentId,
                    scheduleDefinition: .repeated(.weekly(weekday: .friday, hour: 09, minute: 00), startOffsetInDays: 0),
                    completionPolicy: .anytime
                )
            }
        }
    )
}

// swiftlint:enable file_types_order
