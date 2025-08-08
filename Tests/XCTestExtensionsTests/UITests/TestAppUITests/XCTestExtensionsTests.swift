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
        XCTAssert(app.staticTexts["No secure text set ..."].exists)
    }
    
    
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    @available(tvOS, unavailable)
    func testDeleteAndLaunchWithHealthKitSample() throws {
        #if os(macOS) || os(watchOS) || os(visionOS) || os(tvOS)
        throw XCTSkip("Not supported on this platform")
        #endif

        let app = XCUIApplication()
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        XCTAssert(app.buttons["HealthKitDataEntry"].waitForExistence(timeout: 5.0))
        app.buttons["HealthKitDataEntry"].tap()
        
        XCTAssert(app.buttons["Add a HealthKit sample"].waitForExistence(timeout: 3))
        app.buttons["Add a HealthKit sample"].tap()
        
        if app.staticTexts["Has access"].waitForNonExistence(timeout: 2) {
            // if the view isn't telling us that it has access, it's currently requesting access
            app.tables.staticTexts["Turn On All"].tap()
            app.navigationBars["Health Access"].buttons["Allow"].tap()
        }
        
        XCTAssert(app.staticTexts["Did add sample!"].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["Did add sample!"].exists)
        
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
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
        XCTAssert(app.staticTexts["No secure text set ..."].exists)
    }
    
    
    func testTextEntry() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssert(app.buttons["XCTestExtensions"].waitForExistence(timeout: 5.0))
        app.buttons["XCTestExtensions"].tap()

        try app.callTextEntryExtensions()
    }
    
    
    @MainActor
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
        try textField.enter(value: message, options: .skipTextInputValidation)
        XCTAssert(app.staticTexts[message].waitForExistence(timeout: 5))
        #if os(visionOS)
        try textField.enter(value: " ...", options: [.skipTextInputValidation])
        #else
        try textField.enter(value: " ...", options: [.skipTextInputValidation, .tapFromRight])
        #endif
        XCTAssert(app.staticTexts["\(message) ..."].waitForExistence(timeout: 5))

        // Test text field deletion with longer text input
        try textField.delete(count: message.count + 4)
    }
    
    
    func testKeyboardBehavior() throws {
        // make sure you disconnect the hardware keyboard when running this test! Also language must be english.
        let app = XCUIApplication()
        app.launch()

        XCTAssert(app.buttons["DismissKeyboard"].waitForExistence(timeout: 5.0))
        app.buttons["DismissKeyboard"].tap()
        let checkLabel = { (label: String) in
            XCTAssert(app.textFields[label].exists)
            app.textFields[label].selectField()
            #if os(visionOS)
            XCTAssert(app.visionOSKeyboard.wait(for: .runningForeground, timeout: 2.0))
            #elseif !os(macOS)
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2.0))
            #endif

            app.dismissKeyboard()
            #if !os(visionOS) && !os(macOS)
            XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 2.0))
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
    
    
    func testToggleStuff() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssert(app.wait(for: .runningForeground, timeout: 2))
        app.buttons["Toggles / Switches"].tap()
        
        XCTAssert(app.navigationBars["Toggles / Switches"].waitForExistence(timeout: 1))
        print(app.debugDescription)
        
        let toggle = app.switches["Selection"]
        
        func assertToggleState(_ expectedState: Bool, line: UInt = #line) {
            XCTAssert(app.staticTexts["Selection Value, \(expectedState)"].waitForExistence(timeout: 1))
            XCTAssertEqual(toggle.toggleState, expectedState)
        }
        
        assertToggleState(false)
        try toggle.flipToggle()
        assertToggleState(true)
        try toggle.setToggleState(isOn: true)
        assertToggleState(true)
        try toggle.setToggleState(isOn: true)
        assertToggleState(true)
        try toggle.setToggleState(isOn: false)
        assertToggleState(false)
        try toggle.flipToggle()
        assertToggleState(true)
        try toggle.flipToggle()
        assertToggleState(false)
        try toggle.setToggleState(isOn: true)
        assertToggleState(true)
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

        XCTAssertFalse(staticTexts["Button was pressed!"].exists)
    }
}
