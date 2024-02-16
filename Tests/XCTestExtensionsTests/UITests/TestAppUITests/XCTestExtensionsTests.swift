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
    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false
    }

    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    func testDeleteAndLaunch() throws {
#if os(macOS) || os(watchOS)
        throw XCTSkip("Not supported on this platform")
#endif

        let app = XCUIApplication()
        
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        XCTAssert(app.buttons["XCTestExtensions"].waitForExistence(timeout: 5.0))
        app.buttons["XCTestExtensions"].tap()

        XCTAssert(app.staticTexts["No text set ..."].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["No secure text set ..."].waitForExistence(timeout: 5))
    }

    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    func testDeleteAndLaunchFromFirstPage() throws {
#if os(macOS) || os(watchOS)
        throw XCTSkip("Not supported on this platform")
#endif
#if os(visionOS)
        // currently don't know how to swipe on the Reality Launcher. So not a super big use case for us now.
        throw XCTSkip("VisionOS will typically have apps installed on the first screen anyways.")
#endif
        let springboard = XCUIApplication(bundleIdentifier: XCUIApplication.homeScreenBundle)
        springboard.activate()
        springboard.swipeRight()
        
        let app = XCUIApplication()
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        XCTAssert(app.buttons["XCTestExtensions"].waitForExistence(timeout: 5.0))
        app.buttons["XCTestExtensions"].tap()

        XCTAssert(app.staticTexts["No text set ..."].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["No secure text set ..."].waitForExistence(timeout: 5))
    }
    
    func testDisablePasswordAutofill() throws {
        #if os(iOS)
        try disablePasswordAutofill()
        #endif
    }
    
    func testTextEntry() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssert(app.buttons["XCTestExtensions"].waitForExistence(timeout: 5.0))
        app.buttons["XCTestExtensions"].tap()

        try app.callTextEntryExtensions()
    }
    
    func testFlakyTextEntry() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssert(app.buttons["XCTestExtensions"].waitForExistence(timeout: 5.0))
        app.buttons["XCTestExtensions"].tap()

        simulateFlakySimulatorTextEntry = true
        try app.callTextEntryExtensions()
        simulateFlakySimulatorTextEntry = false
    }

    func testLongTextEntries() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssert(app.buttons["XCTestExtensions"].waitForExistence(timeout: 5.0))
        app.buttons["XCTestExtensions"].tap()

        XCTAssert(app.staticTexts["No text set ..."].waitForExistence(timeout: 5))
        let textField = app.textFields["TextField"]

        let message = "This is a very long text and some more"
        try textField.enter(value: message, checkIfTextWasEnteredCorrectly: false)
        XCTAssert(app.staticTexts[message].waitForExistence(timeout: 5))
        try textField.enter(value: " ...", checkIfTextWasEnteredCorrectly: false)
        XCTAssert(app.staticTexts["\(message) ..."].waitForExistence(timeout: 5))
    }

    func testKeyboardBehavior() throws {
        // make sure you disconnect the hardware keyboard when running this test! Also language must be english.
        let app = XCUIApplication()
        app.launch()

        XCTAssert(app.buttons["DismissKeyboard"].waitForExistence(timeout: 5.0))
        app.buttons["DismissKeyboard"].tap()
        let checkLabel = { (label: String) in
            XCTAssert(app.textFields[label].exists)
            app.textFields[label].selectField(dismissKeyboard: false)
            #if os(visionOS)
            XCTAssert(app.visionOSKeyboard.exists)
            #elseif !os(macOS)
            print(app.textFields[label].isSelected)
            XCTAssertTrue(app.keyboards.firstMatch.exists)
            #endif
            sleep(1)

            app.dismissKeyboard()
            sleep(1)
#if !os(visionOS) && !os(macOS)
            // we currently can't check if the keyboard app is not launched
            XCTAssertFalse(app.keyboards.firstMatch.exists)
#endif
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
        XCTAssert(textField.exists)
        try textField.enter(value: "Example Text")
        XCTAssert(staticTexts["Example Text"].waitForExistence(timeout: 5))
        try textField.delete(count: 5)
        XCTAssert(staticTexts["Example"].waitForExistence(timeout: 5))

        try textField.delete(count: 42)
        XCTAssert(staticTexts["No text set ..."].waitForExistence(timeout: 5))

#if os(iOS)
        dismissKeyboard()
        swipeUp()
#endif

        XCTAssert(staticTexts["No secure text set ..."].waitForExistence(timeout: 5))
        let secureTextField = secureTextFields["SecureField"]
        XCTAssert(secureTextField.exists)
        try secureTextField.enter(value: "Secure Text")
        XCTAssert(staticTexts["Secure Text"].waitForExistence(timeout: 5))
        
        try secureTextField.delete(count: 42)
        XCTAssert(staticTexts["No secure text set ..."].waitForExistence(timeout: 5))

        XCTAssertFalse(staticTexts["Button was pressed!"].waitForExistence(timeout: 5.0))
    }
}
