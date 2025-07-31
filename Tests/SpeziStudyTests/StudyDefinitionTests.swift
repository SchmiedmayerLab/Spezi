//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable line_length

import Foundation
import class ModelsR4.Questionnaire
import SpeziFoundation
import SpeziHealthKit
import SpeziHealthKitBulkExport
@testable import SpeziStudyDefinition
import Testing


@Suite
struct StudyDefinitionTests {
    @Test
    func studyEncodingAndDecoding() throws {
        let data = try JSONEncoder().encode(Self.testStudyBundle)
        let decodedStudy = try JSONDecoder().decode(StudyDefinition.self, from: data, configuration: .init(allowTrivialSchemaMigrations: true))
        #expect(try decodedStudy == Self.testStudyBundle)
    }
    
    @Test
    func decodedStudyVersionExtraction() throws {
        let input1 = try JSONEncoder().encode(Self.testStudyBundle)
        #expect(try StudyDefinition.schemaVersion(of: input1, using: JSONDecoder()) == StudyDefinition.schemaVersion)
        
        let input2 = try #require(#"{"schemaVersion":"1.2.3", "glorb": "florb"}"#.data(using: .utf8))
        #expect(try StudyDefinition.schemaVersion(of: input2, using: JSONDecoder()) == Version(1, 2, 3))
    }
    
    @Test
    func componentScheduleDescriptions() {
        typealias Schedule = StudyDefinition.ComponentSchedule.ScheduleDefinition
        #expect(Schedule.once(.date(.init(
            timeZone: .losAngeles, year: 2025, month: 06, day: 27, hour: 13, minute: 37
        ))).description == "once; at 2025-06-27T20:37:00Z")
        #expect(Schedule.once(.date(.init(
            timeZone: .berlin, year: 2025, month: 06, day: 27, hour: 13, minute: 37
        ))).description == "once; at 2025-06-27T11:37:00Z")
        #expect(Schedule.repeated(.daily(interval: 1, hour: 12, minute: 00)).description == "daily @ 12:00")
        #expect(Schedule.repeated(.daily(interval: 1, hour: 09, minute: 07)).description == "daily @ 09:07")
        #expect(Schedule.repeated(.daily(interval: 2, hour: 09, minute: 07)).description == "every 2nd day @ 09:07")
        #expect(Schedule.repeated(.daily(interval: 3, hour: 09, minute: 07)).description == "every 3rd day @ 09:07")
        #expect(Schedule.repeated(.daily(interval: 4, hour: 09, minute: 07)).description == "every 4th day @ 09:07")
        #expect(Schedule.repeated(.daily(interval: 1, hour: 12, minute: 00), offset: .days(2)).description == "daily @ 12:00; offset by 2 days")
        #expect(Schedule.repeated(.daily(interval: 1, hour: 12, minute: 00), offset: .days(2.5)).description == "daily @ 12:00; offset by 2 days, 12 hours")
        #expect(Schedule.repeated(.daily(interval: 1, hour: 09, minute: 07), offset: .minutes(12)).description == "daily @ 09:07; offset by 12 minutes")
        #expect(Schedule.repeated(.daily(interval: 1, hour: 09, minute: 07), offset: .minutes(12.21)).description == "daily @ 09:07; offset by 12 minutes")
        #expect(Schedule.repeated(.daily(interval: 1, hour: 09, minute: 07), offset: .minutes(12.5)).description == "daily @ 09:07; offset by 12 minutes")
        #expect(Schedule.repeated(.daily(interval: 1, hour: 09, minute: 07), offset: .minutes(12.7)).description == "daily @ 09:07; offset by 13 minutes")
        #expect(Schedule.repeated(.daily(interval: 2, hour: 09, minute: 07), offset: .hours(17)).description == "every 2nd day @ 09:07; offset by 17 hours")
        #expect(Schedule.repeated(.daily(interval: 3, hour: 09, minute: 07), offset: .weeks(1)).description == "every 3rd day @ 09:07; offset by 1 week")
        #expect(Schedule.repeated(.daily(interval: 4, hour: 09, minute: 07), offset: .weeks(2)).description == "every 4th day @ 09:07; offset by 2 weeks")
        #expect(Schedule.once(.event(.enrollment)).description == "once; at enrollment")
        #expect(Schedule.once(.event(.enrollment, offsetInDays: 2)).description == "once; at enrollment + 2 days")
        #expect(Schedule.once(.event(.enrollment, offsetInDays: 2, time: .init(hour: 9, minute: 41))).description == "once; at enrollment + 2 days; at 09:41")
    }
}


extension Locale.Language {
    static let english = Locale.Language(identifier: "en")
    static let spanish = Locale.Language(identifier: "es")
    static let german = Locale.Language(identifier: "de")
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
    static var testStudyBundle: StudyDefinition {
        get throws {
            try StudyBundleTests.testStudyBundle.studyDefinition
        }
    }
}
