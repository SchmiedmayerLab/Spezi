//
// This source file is part of the XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTestExtensions


class TestAppUITests: XCTestCase {
    func testDeleteAndLaunch() throws {
        disablePasswordAutofill()
        
        let app = XCUIApplication()
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        XCTAssert(app.staticTexts["No text set ..."].waitForExistence(timeout: 0.5))
        let textField = app.textFields["TextField"]
        textField.enter(value: "Example Text")
        XCTAssert(app.staticTexts["Example Text"].waitForExistence(timeout: 0.5))
        textField.delete(count: 5)
        XCTAssert(app.staticTexts["Example"].waitForExistence(timeout: 0.5))
        
        XCTAssert(app.staticTexts["No secure text set ..."].waitForExistence(timeout: 0.5))
        
        let secureTextField = app.secureTextFields["SecureField"]
        secureTextField.enter(value: "Secure Text")
        XCTAssert(app.staticTexts["Secure Text"].waitForExistence(timeout: 0.5))
        secureTextField.delete(count: 5)
        XCTAssert(app.staticTexts["Secure"].waitForExistence(timeout: 0.5))
    }
}
