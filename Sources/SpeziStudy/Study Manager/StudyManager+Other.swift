//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import class ModelsR4.Questionnaire
import SpeziScheduler
import SpeziStudyDefinition
import SwiftData
import SwiftUI


extension StudyManager {
    /// The user-facing action that is associated with a study-related `SpeziScheduler.Task`
    public enum ScheduledTaskAction: Hashable, Codable {
        case presentInformationalStudyComponent(StudyDefinition.InformationalComponent)
        case answerQuestionnaire(Questionnaire, enrollmentId: PersistentIdentifier)
    }
}

extension Task.Context {
    // ISSUE for some reason only .json works? .propertyList (the default) fails to decode the input?!
    
    /// The ``StudyManager/ScheduledTaskAction`` associated with the task.
    @Property(coding: .json)
    public var studyScheduledTaskAction: StudyManager.ScheduledTaskAction?
}


extension Task.Category {
    /// An informational task, e.g. an article the user should read
    public static let informational = Self.custom("edu.stanford.spezi.SpeziStudy.task.informational")
}


extension View {
    /// Configures the SpeziStudy-specific task category appearances
    public func injectingCustomTaskCategoryAppearances() -> some View {
        self.taskCategoryAppearance(for: .informational, label: "Informational", image: .system("text.rectangle.page"))
    }
}


extension SpeziScheduler.Schedule {
    /// - parameter other: the study definition schedule element which should be turned into a `Schedule`
    /// - parameter participationStartDate: the date at which the user started to participate in the study.
    init(_ other: StudyDefinition.ComponentSchedule.ScheduleDefinition, participationStartDate: Date) {
        switch other {
        case let .repeated(.daily(interval, hour, minute), startOffsetInDays):
            self = .daily(
                interval: interval,
                hour: hour,
                minute: minute,
                second: 0,
                startingAt: participationStartDate.addingTimeInterval(60 * 60 * 24 * TimeInterval(startOffsetInDays)),
                end: .never,
                duration: .tillEndOfDay
            )
        case let .repeated(.weekly(interval, weekday, hour, minute), startOffsetInDays):
            self = .weekly(
                interval: interval,
                weekday: weekday,
                hour: hour,
                minute: minute,
                second: 0,
                startingAt: participationStartDate.addingTimeInterval(60 * 60 * 24 * TimeInterval(startOffsetInDays)),
                end: .never,
                duration: .tillEndOfDay
            )
        }
    }
}
