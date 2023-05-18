//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


extension XCUIApplication {
    /// Dismisses the keyboard if it is currently displayed.
    public func dismissKeyboard() {
        if XCUIApplication().keyboards.buttons["Return"].isHittable {
            XCUIApplication().keyboards.buttons["Return"].tap()
        }
    }
}
