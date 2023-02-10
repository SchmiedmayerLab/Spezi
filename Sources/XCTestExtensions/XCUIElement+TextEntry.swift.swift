//
// This source file is part of the XCTestExtensions open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest

    
extension XCUIElement {
    /// Delete a fixed number of characters in a text field or secure text field.
    /// - Parameter count: The number of characters that should be deleted.
    public func delete(count: Int) {
        coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.5)).tap()
        XCTAssert(XCUIApplication().keyboards.firstMatch.waitForExistence(timeout: 2.0))
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count))
    }
    
    /// Type a text in a text field or secure text field.
    /// - Parameter value: The text that should be typed.
    public func enter(value: String) {
        tap()
        XCTAssert(XCUIApplication().keyboards.firstMatch.waitForExistence(timeout: 2.0))
        typeText(value)
    }
}
