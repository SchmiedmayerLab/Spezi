//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension StudyDefinition {
    /// Study Component which prompts the participant to read an informational article
    public struct InformationalComponent: Identifiable, StudyDefinitionElement {
        public var id: UUID
        public var title: String
        public var headerImage: String
        public var body: String
        
        public init(id: UUID, title: String, headerImage: String, body: String) {
            self.id = id
            self.title = title
            self.headerImage = headerImage
            self.body = body
        }
    }
}
