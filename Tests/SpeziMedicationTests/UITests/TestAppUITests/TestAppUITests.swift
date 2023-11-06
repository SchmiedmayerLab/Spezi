//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


class TestAppUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
    }
    
    
    @MainActor
    func testSpeziMedication() async throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.staticTexts["No Medications"].waitForExistence(timeout: 2))
        
        app.buttonTap("Show Settings")
        
        XCTAssertTrue(app.navigationBars["Medication Settings"].buttons["Add New Medication"].waitForExistence(timeout: 10))
        app.navigationBars["Medication Settings"].buttons["Add New Medication"].tap()
        
        app.buttonTap("Medication 1")
        app.buttonTap("Add Medication")
        app.buttonTap("Save Medications")
        
        try await Task.sleep(for: .seconds(2))
        
        XCTAssertTrue(app.staticTexts["Medication 1 - Dosage 1.1"].waitForExistence(timeout: 2))
    }
    
    func testSpeziMedicationDelete() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.staticTexts["No Medications"].waitForExistence(timeout: 2))
        
        app.buttonTap("Show Settings")
        
        XCTAssertTrue(app.staticTexts["Use the \"+\" button at the top to add all the medications you take."].waitForExistence(timeout: 2))
        
        XCTAssertTrue(app.navigationBars["Medication Settings"].buttons["Add New Medication"].waitForExistence(timeout: 10))
        app.navigationBars["Medication Settings"].buttons["Add New Medication"].tap()
        
        app.buttonTap("Medication 1")
        app.buttonTap("Add Medication")
        
        app.buttonTap("Medication 1, Dosage 1.1")
        app.buttonTap("Delete")
        
        XCTAssertTrue(app.staticTexts["Use the \"+\" button at the top to add all the medications you take."].waitForExistence(timeout: 2))
    }
    
    func testSpeziMedicationDismiss() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.staticTexts["No Medications"].waitForExistence(timeout: 2))
        
        app.buttonTap("Show Settings")
        
        XCTAssertTrue(app.navigationBars["Medication Settings"].buttons["Add New Medication"].waitForExistence(timeout: 10))
        app.navigationBars["Medication Settings"].buttons["Add New Medication"].tap()
        
        app.buttonTap("Medication 1")
        app.buttonTap("Add Medication")
        
        app.buttonTap("Cancel")
        app.buttonTap("Discard Changes")
        
        XCTAssertTrue(app.staticTexts["No Medications"].waitForExistence(timeout: 2))
    }
    
    func testSpeziMedicationEdit() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.staticTexts["No Medications"].waitForExistence(timeout: 2))
        
        app.buttonTap("Show Settings")
        
        XCTAssertTrue(app.navigationBars["Medication Settings"].buttons["Add New Medication"].waitForExistence(timeout: 10))
        app.navigationBars["Medication Settings"].buttons["Add New Medication"].tap()
        
        app.buttonTap("Medication 1")
        app.buttonTap("Add Medication")
        
        XCTAssertTrue(app.navigationBars["Medication Settings"].buttons["Add New Medication"].waitForExistence(timeout: 10))
        app.navigationBars["Medication Settings"].buttons["Add New Medication"].tap()
        
        app.buttonTap("Medication 1")
        
        XCTAssertTrue(app.staticTexts["Medication with this dosage already exists."].waitForExistence(timeout: 2))
        
        app.buttonTap("Dosage 1.2")
        app.buttonTap("Add Medication")
        
        app.buttonTap("Medication 1, Dosage 1.1")
        
        XCTAssertTrue(app.staticTexts["Medication with this dosage already exists."].waitForExistence(timeout: 2))
        app.buttonTap("Dosage 1.3")
        
        XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        XCTAssertTrue(app.buttons["Medication 1, Dosage 1.3"].waitForExistence(timeout: 2))
    }
}
