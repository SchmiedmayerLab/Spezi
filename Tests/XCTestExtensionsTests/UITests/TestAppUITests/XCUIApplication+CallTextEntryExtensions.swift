//
// This source file is part of the XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import XCTestExtensions


extension XCUIApplication {
    fileprivate func callTextEntryExtensions() throws {
        XCTAssert(staticTexts["No text set ..."].waitForExistence(timeout: 5))
        let textField = textFields["TextField"]
        try textField.enter(value: "Example Text")
        XCTAssert(staticTexts["Example Text"].waitForExistence(timeout: 5))
        try textField.delete(count: 5)
        XCTAssert(staticTexts["Example"].waitForExistence(timeout: 5))
        
        try textField.delete(count: 42)
        XCTAssert(staticTexts["No text set ..."].waitForExistence(timeout: 5))
        
        swipeUp()
        
        XCTAssert(staticTexts["No secure text set ..."].waitForExistence(timeout: 5))
        let secureTextField = secureTextFields["SecureField"]
        try secureTextField.enter(value: "Secure Text")
        XCTAssert(staticTexts["Secure Text"].waitForExistence(timeout: 5))
        try secureTextField.delete(count: 5)
        XCTAssert(staticTexts["Secure"].waitForExistence(timeout: 5))
        
        try secureTextField.delete(count: 42)
        XCTAssert(staticTexts["No secure text set ..."].waitForExistence(timeout: 5))
    }
}
