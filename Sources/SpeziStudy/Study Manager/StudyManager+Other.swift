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
        case answerQuestionnaire(StudyDefinition.QuestionnaireComponent)
        case promptTimedWalkingTest(StudyDefinition.TimedWalkingTestComponent)
    }
}

extension Task.Context {
    /// The study-related context of a Task
    public struct StudyContext: Codable, Hashable, Sendable {
        /// The identifier of the study to which the Task belongs
        public let studyId: StudyDefinition.ID
        /// The identifier of the study component for which the Task was created
        public let componentId: StudyDefinition.Component.ID
        /// The identifier of the specific study schedule from which the Task was created
        public let scheduleId: StudyDefinition.ComponentSchedule.ID
        /// The `PersistentIdentifier` of the ``StudyEnrollment`` this `Task` belongs to.
        public let enrollmentId: PersistentIdentifier
    }
    
    /// The study to which this Task belongs, and the component for which it was scheduled.
    @Property(coding: .json)
    public var studyContext: StudyContext?
    
    /// The ``StudyManager/ScheduledTaskAction`` associated with the task.
    @Property(coding: .json)
    public var studyScheduledTaskAction: StudyManager.ScheduledTaskAction?
}


extension Task.Category {
    /// An informational task, e.g. an article the user should read
    public static let informational = Self.custom("edu.stanford.spezi.SpeziStudy.task.informational")
    
    /// An active task, i.e., some action the participant should perform
    public static let activeTask = Self.custom("edu.stanford.spezi.SpeziStudy.task.activeTask")
}


extension View {
    /// Configures the SpeziStudy-specific task category appearances
    public func injectingCustomTaskCategoryAppearances() -> some View {
        self.taskCategoryAppearance(for: .informational, label: "Informational", image: .system("text.rectangle.page"))
    }
}


extension SpeziScheduler.Schedule {
    /// Creates a `SpeziScheduler.Schedule` from a `StudyDefinition.ComponentSchedule.ScheduleDefinition.repeated`.
    ///
    /// - parameter other: the study definition schedule element which should be turned into a `Schedule`
    /// - parameter participationStartDate: the date at which the user started to participate in the study.
    ///
    /// - invariant: `other` MUST be a `.repeated` `ScheduleDefinition`, otherwise the function will abort.
    static func fromRepeated(_ other: StudyDefinition.ComponentSchedule.ScheduleDefinition, participationStartDate: Date) -> Self {
        switch other {
        case let .repeated(.daily(interval, hour, minute), offset):
            return .daily(
                interval: interval,
                hour: hour,
                minute: minute,
                second: 0,
                startingAt: participationStartDate.addingTimeInterval(offset.timeInterval),
                end: .never,
                duration: .tillEndOfDay
            )
        case let .repeated(.weekly(interval, weekday, hour, minute), offset):
            return .weekly(
                interval: interval,
                weekday: weekday,
                hour: hour,
                minute: minute,
                second: 0,
                startingAt: participationStartDate.addingTimeInterval(offset.timeInterval),
                end: .never,
                duration: .tillEndOfDay
            )
        case .after, .once:
            preconditionFailure("Unexpected input: expected .repeated, got '\(other)'")
        }
    }
}
