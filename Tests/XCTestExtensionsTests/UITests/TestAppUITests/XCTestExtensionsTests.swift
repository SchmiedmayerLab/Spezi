//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import XCTestExtensions


class XCTestExtensionsTests: XCTestCase {
    func testDeleteAndLaunch() throws {
        let app = XCUIApplication()
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        app.staticTexts["XCTestExtensions"].tap()
        
        XCTAssert(app.staticTexts["No text set ..."].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["No secure text set ..."].waitForExistence(timeout: 5))
    }
    
    func testDeleteAndLaunchFromFirstPage() throws {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        springboard.swipeRight()
        
        let app = XCUIApplication()
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        app.staticTexts["XCTestExtensions"].tap()
        
        XCTAssert(app.staticTexts["No text set ..."].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["No secure text set ..."].waitForExistence(timeout: 5))
    }
    
    func testDisablePasswordAutofill() throws {
        try disablePasswordAutofill()
    }
    
    func testTextEntry() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.staticTexts["XCTestExtensions"].tap()
        
        simulateFlakySimulatorTextEntry = false
        try app.callTextEntryExtensions()
    }
    
    func testFlakyTextEntry() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.staticTexts["XCTestExtensions"].tap()
        
        simulateFlakySimulatorTextEntry = true
        try app.callTextEntryExtensions()
    }

    func testKeyboardBehavior() throws {
        // make sure you disconnect the hardware keyboard when running this test! Also language must be english.
        let app = XCUIApplication()
        app.launch()

        app.staticTexts["DismissKeyboard"].tap()

        let checkLabel = { (label: String) in
            app.textFields[label].selectField(dismissKeyboard: false)
            XCTAssertTrue(app.keyboards.firstMatch.exists)
            print(app.keyboards.buttons.debugDescription)
            sleep(1)

            app.dismissKeyboard()
            sleep(1)
            XCTAssertFalse(app.keyboards.firstMatch.exists)
        }

        // this way we know exactly which button failed by line numbers.
        checkLabel("Continue")
        checkLabel("Done")
        checkLabel("Go")
        checkLabel("Join")
        checkLabel("Next")
        checkLabel("Return")
        checkLabel("Route")
        checkLabel("Search")
        checkLabel("Send")
    }
}


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

        dismissKeyboard()
        swipeUp()

        XCTAssert(staticTexts["No secure text set ..."].waitForExistence(timeout: 5))
        let secureTextField = secureTextFields["SecureField"]
        try secureTextField.enter(value: "Secure Text")
        XCTAssert(staticTexts["Secure Text"].waitForExistence(timeout: 5))
        
        try secureTextField.delete(count: 42)
        XCTAssert(staticTexts["No secure text set ..."].waitForExistence(timeout: 5))

        XCTAssertFalse(staticTexts["Button was pressed!"].waitForExistence(timeout: 5.0))
    }
}
