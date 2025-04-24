//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
@preconcurrency import class ModelsR4.Questionnaire


extension StudyDefinition {
    /// Study Component which prompts the participant to answer a questionnaire
    public struct QuestionnaireComponent: Identifiable, StudyDefinitionElement {
        /// - parameter id: the id of this study component, **not** of the questionnaire
        public let id: UUID
        public let questionnaire: Questionnaire
        
        public init(id: UUID, questionnaire: Questionnaire) {
            self.id = id
            self.questionnaire = questionnaire
        }
    }
}
