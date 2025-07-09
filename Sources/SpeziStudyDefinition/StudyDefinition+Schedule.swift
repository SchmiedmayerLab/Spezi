//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import enum SpeziScheduler.AllowedCompletionPolicy
import enum SpeziScheduler.NotificationThread


extension StudyDefinition {
    /// A schedule, defining when a specific ``Component`` should get activated.
    ///
    /// A component schedule associates a ``Component`` (identified via its unique ``Component/id``) with a ``ScheduleDefinition-swift.enum``.
    ///
    /// When enrolling into a study, SpeziStudy's [`StudyManager`](https://swiftpackageindex.com/stanfordspezi/spezistudy/documentation/spezistudy/studymanager)
    /// will process the ``StudyDefinition``'s schedules into [SpeziScheduler](https://swiftpackageindex.com/StanfordSpezi/SpeziScheduler/documentation/spezischeduler)
    /// [`Task`](https://swiftpackageindex.com/StanfordSpezi/SpeziScheduler/documentation/spezischeduler/task)s, `Event`s for which can then be queried by an app and displayed to a user.
    ///
    /// A ``StudyDefinition`` may not contain multiple schedules for the same component.
    ///
    /// - Note: These schedules only apply to user-interactive ``Component``s (e.g.: ``QuestionnaireComponent`` or ``InformationalComponent``).
    ///     Non-user-interactive components (e.g.: ``HealthDataCollectionComponent``) are always implicitly activated upon enrollment, and are active for the entire duration of the participant's enrollment in the study.
    ///
    /// ## Topics
    ///
    /// ### Initializers
    /// - ``init(id:componentId:scheduleDefinition:completionPolicy:notifications:)``
    ///
    /// ### Instance Properties
    /// - ``componentId``
    /// - ``scheduleDefinition-swift.property``
    /// - ``completionPolicy``
    ///
    /// ### Other
    /// - ``ScheduleDefinition-swift.enum``
    public struct ComponentSchedule: StudyDefinitionElement, Identifiable {
        /// A schedule, defining when a ``Component`` should be activated.
        ///
        /// ## Topics
        /// ### Schedule Kinds
        /// - ``repeated(_:offset:)``
        /// ### Supporting Types
        /// - ``RepetitionPattern``
        public enum ScheduleDefinition: StudyDefinitionElement {
            /// A schedule that should run in response to an event within the study's lifecycle.
            case after(StudyLifecycleEvent, offset: Duration = .zero)
            
            /// A schedule that should run exactly once, at a specific date in the user's time zone.
            case once(DateComponents) // DateComponents bc we need it to be TimeZone independent...
            
            /// A schedule that will run multiple times, based on a repetition pattern (e.g.: weekly).
            ///
            /// This case defines a schedule which will activate repeatedly, based on a repetition pattern.
            /// - parameter pattern: The pattern based on which the schedule should repeat itself.
            /// - parameter offset: The offsetbetween the participant's enrollment into the study and the first time the schedule should take effect.
            case repeated(_ pattern: RepetitionPattern, offset: Duration = .zero)
            
            /// Pattern defining how a repeating ``StudyDefinition/ComponentSchedule/ScheduleDefinition-swift.enum`` should repeat itself.
            public enum RepetitionPattern: StudyDefinitionElement { // swiftlint:disable:this nesting
                /// A repetition pattern that will take effect daily, at the specified `hour` and `minute`.
                case daily(interval: Int = 1, hour: Int, minute: Int = 0)
                /// A repetition pattern that will take effect weekly, at the specified `weekday`, `hour`, and `minute`.
                case weekly(interval: Int = 1, weekday: Locale.Weekday, hour: Int, minute: Int = 0)
            }
        }
        
        public enum NotificationsConfig: StudyDefinitionElement {
            /// There should not be any notifications for occurrences of this schedule.
            case disabled
            /// There should be notifications for occurrences of this schedule.
            /// - parameter thread: the notification thread used to group the notifications
            case enabled(thread: SpeziScheduler.NotificationThread)
            
            /// The resulting effective notification thread
            public var thread: SpeziScheduler.NotificationThread {
                switch self {
                case .disabled: .none
                case .enabled(let thread): thread
                }
            }
        }
        
        /// This schedule's unique, stable identifier.
        public var id: UUID
        /// The identifier of the component this schedule is referencing
        public var componentId: StudyDefinition.Component.ID
        /// The schedule itself
        public var scheduleDefinition: ScheduleDefinition
        /// Defines when an `Event` scheduled based on this schedule is allowed to be marked as completed.
        public var completionPolicy: SpeziScheduler.AllowedCompletionPolicy
        /// Whether notifications should be sent for occurrences of this schedule.
        public var notifications: NotificationsConfig
        
        /// Creates a new `ComponentSchedule`.
        public init(
            id: UUID,
            componentId: StudyDefinition.Component.ID,
            scheduleDefinition: ScheduleDefinition,
            completionPolicy: SpeziScheduler.AllowedCompletionPolicy,
            notifications: NotificationsConfig
        ) {
            self.id = id
            self.componentId = componentId
            self.scheduleDefinition = scheduleDefinition
            self.completionPolicy = completionPolicy
            self.notifications = notifications
        }
    }
}


extension StudyDefinition.ComponentSchedule.ScheduleDefinition: CustomStringConvertible {
    private static let ordinalsFormatter: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .ordinal
        return fmt
    }()
    
    public var description: String {
        switch self {
        case let .repeated(.daily(interval, hour, minute), offset):
            let intervalDesc = switch interval {
            case ...0: ""
            case 1: "daily"
            default: "every \(Self.ordinalsFormatter.string(from: .init(value: interval)) ?? "\(interval)th") day"
            }
            return "\(intervalDesc) @ \(String(format: "%.2d", hour)):\(String(format: "%.2d", minute))\(Self.offsetDesc(offset))"
        case let .repeated(.weekly(interval, weekday, hour, minute), offset):
            let intervalDesc = switch interval {
            case ...0: ""
            case 1: "weekly"
            default: "every \(Self.ordinalsFormatter.string(from: .init(value: interval)) ?? "\(interval)th") week"
            }
            return "\(intervalDesc) @ \(weekday.rawValue) \(String(format: "%.2d", hour)):\(String(format: "%.2d", minute))\(Self.offsetDesc(offset))"
        case let .after(studyLifecycleEvent, offset):
            return "after \(studyLifecycleEvent)\(Self.offsetDesc(offset))"
        case .once(let dateComponents):
            let date = Calendar.current.date(from: dateComponents)
            return "once; at \(date?.ISO8601Format() ?? dateComponents.description)"
        }
    }
    
    private static func offsetDesc(_ offset: Duration) -> String {
        let fmt = Duration.UnitsFormatStyle(
            allowedUnits: [.minutes, .hours, .days, .weeks],
            width: .wide
        )
        return if offset == .zero {
            ""
        } else {
            "; offset by \(offset.formatted(fmt))"
        }
    }
}


extension StudyLifecycleEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .enrollment:
            "enrollment"
        case .unenrollment:
            "unenrollment"
        case .studyEnd:
            "studyEnd"
        case .completedTask(let componentId):
            "completedTask(\(componentId.uuidString))"
        }
    }
}
