//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension StudyDefinition {
    /// Performs a simple validation of the study definition's integrity, checking e.g. that there are no references to non-existing componts.
    public func validate() -> Bool {
        guard componentSchedules.allSatisfy({ self.component(withId: $0.componentId) != nil }) else {
            return false
        }
        return true
    }
}
