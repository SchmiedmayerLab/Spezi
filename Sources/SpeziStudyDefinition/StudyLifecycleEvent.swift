//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// An event that can happen over the course of a study's lifecycle, from the perspective of a participant.
public enum StudyLifecycleEvent: Hashable, Codable, Sendable {
    /// The event representing the participant's enrollment into the study
    case enrollment
    /// The event representing the participant's unenrollment from the study
    case unenrollment
    /// The event representing the official end of the study
    case studyEnd
    /// The event representing the completion of a scheduled occurrence of a component.
    case completedTask(componentId: StudyDefinition.Component.ID)
}
