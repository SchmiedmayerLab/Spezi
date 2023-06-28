//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OSLog
import XCTest


extension XCTestCase {
    /// Navigates to the iOS settings app and disables the password autofill functionality.
    public func disablePasswordAutofill() throws {
        let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settingsApp.terminate()
        settingsApp.launch()
        
        if settingsApp.staticTexts["PASSWORDS"].waitForExistence(timeout: 5.0) {
            settingsApp.staticTexts["PASSWORDS"].tap()
        }
        
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.secureTextFields["Passcode field"].waitForExistence(timeout: 30.0) {
            let passcodeInput = springboard.secureTextFields["Passcode field"]
            passcodeInput.tap()
            
            sleep(2)
            
            passcodeInput.typeText("1234\r")
            
            sleep(2)
        } else {
            os_log("Could not enter the passcode in the device to enter the password section in the settings app.")
            throw XCTestError(.failureWhileWaiting)
        }
        
        var counter = 0
        let passwordOptionsCell = settingsApp.tables.cells["PasswordOptionsCell"]
        while !passwordOptionsCell.isHittable || counter > 10 {
            _ = settingsApp.tables.cells["PasswordOptionsCell"].waitForExistence(timeout: 2.0)
            counter += 1
        }
        
        sleep(3)
        
        settingsApp.tables.cells["PasswordOptionsCell"].tap()
        
        let autoFillPasswords: String
        if #available(iOS 17.0, *) {
            autoFillPasswords = "AutoFill Passwords and Passkeys"
        } else {
            autoFillPasswords = "AutoFill Passwords"
        }
        
        XCTAssert(settingsApp.switches[autoFillPasswords].waitForExistence(timeout: 5))
        if settingsApp.switches[autoFillPasswords].value as? String == "1" {
            settingsApp.switches[autoFillPasswords].tap()
        }
    }
}
