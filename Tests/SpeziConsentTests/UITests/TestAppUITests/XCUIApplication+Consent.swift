//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTestExtensions

extension XCUIApplication {
//    func hitConsentButton() {
//        if staticTexts["This is the first markdown example"].isHittable {
//            staticTexts["This is the first markdown example"].swipeUp()
//        } else if staticTexts["This is the second markdown example"].isHittable {
//            staticTexts["This is the second markdown example"].swipeUp()
//        } else {
//            print("Can not scroll down.")
//        }
//        XCTAssert(buttons["I Consent"].waitForExistence(timeout: 2))
//        buttons["I Consent"].tap()
//    }
    
    
    func fillOutSimpleConsent(
        consentTitle: String,
        consentText: String,
        continueButton: XCUIElement
    ) throws {
        XCTAssert(staticTexts[consentTitle].waitForExistence(timeout: 2))
        XCTAssert(staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", consentText)).element.waitForExistence(timeout: 1))
        XCTAssertFalse(continueButton.isEnabled)

        #if targetEnvironment(simulator) && (arch(i386) || arch(x86_64))
        throw XCTSkip("PKCanvas view-related tests are currently skipped on Intel-based iOS simulators due to a metal bug on the simulator.")
        #endif

        XCTAssert(staticTexts["First Name"].waitForExistence(timeout: 2))
        try textFields["Enter your first name…"].enter(value: "Leland")
        XCTAssertFalse(continueButton.isEnabled)
        XCTAssert(staticTexts["Last Name"].waitForExistence(timeout: 2))
        try textFields["Enter your last name…"].enter(value: "Stanford")
        XCTAssertFalse(continueButton.isEnabled)
        
        XCTAssert(staticTexts["Name: Leland Stanford"].waitForExistence(timeout: 2))

        #if !os(macOS)
        XCTAssert(buttons["Clear"].waitForExistence(timeout: 2.0))
        XCTAssertFalse(buttons["Clear"].isEnabled)
        
        XCTAssertFalse(continueButton.isEnabled)
        staticTexts["Name: Leland Stanford"].swipeRight()
        XCTAssert(continueButton.isEnabled)
        
        XCTAssert(buttons["Clear"].waitForExistence(timeout: 2.0))
        XCTAssert(buttons["Clear"].isEnabled)
        buttons["Clear"].tap()
        XCTAssertFalse(continueButton.isEnabled)
        
        XCTAssert(buttons["Clear"].waitForExistence(timeout: 2.0))
        XCTAssertFalse(buttons["Clear"].isEnabled)
        
        XCTAssert(scrollViews["Signature Field"].waitForExistence(timeout: 2))
        scrollViews["Signature Field"].swipeRight()
        XCTAssert(continueButton.isEnabled)
        
        XCTAssert(buttons["Clear"].waitForExistence(timeout: 2.0))
        XCTAssert(buttons["Clear"].isEnabled)
        XCTAssert(continueButton.isEnabled)
        #else
        XCTAssert(textFields["Signature Field"].waitForExistence(timeout: 2))
        try textFields["Signature Field"].enter(value: "Leland Stanford")
        #endif
        
        XCTAssert(continueButton.isEnabled)
        continueButton.tap()
    }
    
    
    func fillOutInteractiveConsent( // swiftlint:disable:this function_body_length
        consentTitle: String,
        consentText: String,
        continueButton: XCUIElement
    ) throws {
        XCTAssert(staticTexts[consentTitle].waitForExistence(timeout: 1))
        XCTAssert(staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", consentText)).element.waitForExistence(timeout: 1))
        
        let shareButton = buttons["Share Consent Form"]
        XCTAssert(shareButton.waitForExistence(timeout: 1))
        
        func assertExpectedCompletion(_ isComplete: Bool, line: UInt = #line) {
            for button in [continueButton, shareButton] {
                XCTAssertEqual(button.isEnabled, isComplete, line: line)
            }
        }
        
        assertExpectedCompletion(false)
        
        func flipToggle(beforeValue: Bool, afterValue: Bool, line: UInt = #line) throws {
            let element = switches["ConsentForm:data-sharing"].firstMatch
            XCTAssert(element.exists, line: line)
            XCTAssertEqual(try XCTUnwrap(XCTUnwrap(element.value) as? String), beforeValue ? "1" : "0", line: line)
            try element.toggleSwitch()
            sleep(for: .seconds(0.25))
            XCTAssertEqual(try XCTUnwrap(XCTUnwrap(element.value) as? String), afterValue ? "1" : "0", line: line)
        }
        
        assertExpectedCompletion(false)
        try flipToggle(beforeValue: false, afterValue: true)
        assertExpectedCompletion(false)
        
        #if !os(visionOS)
        swipeUp()
        #endif
        sleep(for: .seconds(1))
        
        func select(in elementId: String, option: String?, expectedCurrentSelection: String?, line: UInt = #line) throws {
            let noSelectionTitle = "(No selection)"
            let button = buttons["ConsentForm:\(elementId)"]
            XCTAssert(button.exists)
            XCTAssert(button.staticTexts[expectedCurrentSelection ?? noSelectionTitle].waitForExistence(timeout: 1), line: line)
            button.tap()
            buttons[option ?? noSelectionTitle].tap()
            sleep(for: .seconds(0.25))
            XCTAssert(button.staticTexts[expectedCurrentSelection ?? noSelectionTitle].waitForNonExistence(timeout: 1), line: line)
            XCTAssert(button.staticTexts[option ?? noSelectionTitle].waitForExistence(timeout: 1), line: line)
        }
        
        assertExpectedCompletion(false)
        try select(in: "select1", option: "Mountains", expectedCurrentSelection: nil)
        assertExpectedCompletion(false)
        
        try select(in: "select2", option: "No", expectedCurrentSelection: nil)
        
        do {
            for (nameComponent, name) in zip(["first", "last"], ["Leland", "Stanford"]) {
                let textField = textFields["Enter your \(nameComponent) name…"]
                XCTAssert(textField.waitForExistence(timeout: 2))
                try textField.enter(value: name)
            }
            assertExpectedCompletion(false)
            let signatureCanvas = scrollViews["ConsentForm:sig"]
            signatureCanvas.swipeRight()
        }
        sleep(for: .seconds(1))
        
        assertExpectedCompletion(true)
        try select(in: "select1", option: nil, expectedCurrentSelection: "Mountains")
        assertExpectedCompletion(false)
        try select(in: "select1", option: "Beach", expectedCurrentSelection: nil)
        assertExpectedCompletion(true)
        try select(in: "select1", option: "Mountains", expectedCurrentSelection: "Beach")
        assertExpectedCompletion(true)
        
        #if !os(visionOS)
        swipeDown()
        #endif
        sleep(for: .seconds(1))
        
        assertExpectedCompletion(true)
        try flipToggle(beforeValue: true, afterValue: false)
        assertExpectedCompletion(false)
        try flipToggle(beforeValue: false, afterValue: true)
        assertExpectedCompletion(true)
        
        shareButton.tap()
        assertShareSheetTextElementExists(consentTitle)
        navigationBars["UIActivityContentView"].buttons["header.closeButton"].tap()
        
        continueButton.tap()
    }
}
