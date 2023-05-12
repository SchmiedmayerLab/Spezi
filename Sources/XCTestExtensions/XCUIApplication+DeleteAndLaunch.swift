//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


extension XCUIApplication {
    /// Deletes the application from the iOS springboard (iOS home screen) and launches it after it has been deleted and reinstalled.
    /// - Parameter appName: The name of the application as displayed on the springboard (iOS home screen).
    public func deleteAndLaunch(withSpringboardAppName appName: String) {
        self.terminate()
        
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        
        if springboard.icons[appName].firstMatch.waitForExistence(timeout: 10.0) {
            if !springboard.icons[appName].firstMatch.isHittable {
                springboard.swipeLeft()
            }
            
            XCTAssertTrue(springboard.icons[appName].firstMatch.isHittable)
            springboard.icons[appName].firstMatch.press(forDuration: 1.5)
            
            XCTAssertTrue(springboard.collectionViews.buttons["Remove App"].waitForExistence(timeout: 5.0))
            springboard.collectionViews.buttons["Remove App"].tap()
            XCTAssertTrue(springboard.alerts["Remove “\(appName)”?"].scrollViews.otherElements.buttons["Delete App"].waitForExistence(timeout: 5.0))
            springboard.alerts["Remove “\(appName)”?"].scrollViews.otherElements.buttons["Delete App"].tap()
            XCTAssertTrue(springboard.alerts["Delete “\(appName)”?"].scrollViews.otherElements.buttons["Delete"].waitForExistence(timeout: 5.0))
            springboard.alerts["Delete “\(appName)”?"].scrollViews.otherElements.buttons["Delete"].tap()
        }
        
        self.launch()
    }
}
