//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziScheduler


extension StudyDefinition {
    /// A schedule, defining when a specific ``Component`` should get activated.
    ///
    /// A component schedule associates a ``Component`` (identified via its unique ``Component/id``) with a ``ScheduleDefinition-swift.enum``.
    ///
    /// When enrolling into a study, SpeziStudy's [`StudyManager`](https://swiftpackageindex.com/stanfordspezi/spezistudy/documentation/spezistudy/studymanager)
    /// will process the ``StudyDefinition``'s schedules into [SpeziScheduler](https://swiftpackageindex.com/StanfordSpezi/SpeziScheduler/documentation/spezischeduler)
    /// [`Task`](https://swiftpackageindex.com/StanfordSpezi/SpeziScheduler/documentation/spezischeduler/task)s, `Event`s for which can then be queried by an app and displayed to a user.
    ///
    /// A ``StudyDefinition`` may contain multiple schedules for the same component; SpeziStudy will process all schedules independently of each other,
    /// and the resulting effective schedule for the component will be the union of all individual schedules.
    ///
    /// - Note: These schedules only apply to user-interactive ``Component``s (e.g.: ``QuestionnaireComponent`` or ``InformationalComponent``).
    ///     Non-user-interactive components (e.g.: ``HealthDataCollectionComponent``) are always implicitly activated upon enrollment, and are active for the entire duration of the participant's enrollment in the study.
    ///
    /// ## Topics
    ///
    /// ### Initializers
    /// - ``init(componentId:scheduleDefinition:completionPolicy:)``
    ///
    /// ### Instance Properties
    /// - ``componentId``
    /// - ``scheduleDefinition-swift.property``
    /// - ``completionPolicy``
    ///
    /// ### Other
    /// - ``ScheduleDefinition-swift.enum``
    public struct ComponentSchedule: StudyDefinitionElement {
        /// A schedule, defining when a ``Component`` should be activated.
        ///
        /// ## Topics
        /// ### Schedule Kinds
        /// - ``repeated(_:startOffsetInDays:)``
        /// ### Supporting Types
        /// - ``RepetitionPattern``
        public enum ScheduleDefinition: StudyDefinitionElement {
            /// A schedule that will run multiple times, based on a repetition pattern (e.g.: weekly).
            ///
            /// This case defines a schedule which will activate repeatedly, based on a repetition pattern.
            /// - parameter pattern: The pattern based on which the schedule should repeat itself.
            /// - parameter startOffsetInDays: The number of days between the participants enrollment into the study and the first time the schedule should take effect.
            case repeated(_ pattern: RepetitionPattern, startOffsetInDays: Int)
            
            /// Pattern defining how a repeating ``StudyDefinition/ComponentSchedule/ScheduleDefinition-swift.enum`` should repeat itself.
            public enum RepetitionPattern: StudyDefinitionElement { // swiftlint:disable:this nesting
                /// A repetition pattern that will take effect daily, at the specified `hour` and `minute`.
                case daily(interval: Int = 1, hour: Int, minute: Int = 0)
                /// A repetition pattern that will take effect weekly, at the specified `weekday`, `hour`, and `minute`.
                case weekly(interval: Int = 1, weekday: Locale.Weekday, hour: Int, minute: Int = 0)
            }
        }
        
        /// The identifier of the component this schedule is referencing
        public var componentId: StudyDefinition.Component.ID
        /// The schedule itself
        public var scheduleDefinition: ScheduleDefinition
        /// Defines when an `Event` scheduled based on this schedule is allowed to be marked as completed.
        public var completionPolicy: SpeziScheduler.AllowedCompletionPolicy
        
        /// Creates a new `ComponentSchedule`.
        public init(
            componentId: StudyDefinition.Component.ID,
            scheduleDefinition: ScheduleDefinition,
            completionPolicy: SpeziScheduler.AllowedCompletionPolicy
        ) {
            self.componentId = componentId
            self.scheduleDefinition = scheduleDefinition
            self.completionPolicy = completionPolicy
        }
    }
}
