//
// This source file is part of the XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import XCTestExtensions


class TestAppUITests: XCTestCase {
    func testDeleteAndLaunch() throws {
        let app = XCUIApplication()
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        XCTAssert(app.staticTexts["No text set ..."].waitForExistence(timeout: 5.0))
        XCTAssert(app.staticTexts["No secure text set ..."].waitForExistence(timeout: 5.0))
    }
    
    func testDisablePasswordAutofill() throws {
        disablePasswordAutofill()
    }
    
    func testTextEntry() throws {
        let app = XCUIApplication()
        app.launch()
        
        simulateFlakySimulatorTextEntry = false
        app.callTextEntryExtensions()
    }
    
    func testFlakyTextEntry() throws {
        let app = XCUIApplication()
        app.launch()
        
        simulateFlakySimulatorTextEntry = true
        app.callTextEntryExtensions()
    }
}


extension XCUIApplication {
    fileprivate func callTextEntryExtensions() {
        XCTAssert(staticTexts["No text set ..."].waitForExistence(timeout: 5.0))
        let textField = textFields["TextField"]
        textField.enter(value: "Example Text")
        XCTAssert(staticTexts["Example Text"].waitForExistence(timeout: 5.0))
        textField.delete(count: 5)
        XCTAssert(staticTexts["Example"].waitForExistence(timeout: 5.0))
        
        textField.delete(count: 42)
        XCTAssert(staticTexts["No text set ..."].waitForExistence(timeout: 5.0))
        
        swipeUp()
        
        XCTAssert(staticTexts["No secure text set ..."].waitForExistence(timeout: 5.0))
        let secureTextField = secureTextFields["SecureField"]
        secureTextField.enter(value: "Secure Text")
        XCTAssert(staticTexts["Secure Text"].waitForExistence(timeout: 5.0))
        secureTextField.delete(count: 5)
        XCTAssert(staticTexts["Secure"].waitForExistence(timeout: 5.0))
        
        secureTextField.delete(count: 42)
        XCTAssert(staticTexts["No secure text set ..."].waitForExistence(timeout: 5.0))
    }
}
