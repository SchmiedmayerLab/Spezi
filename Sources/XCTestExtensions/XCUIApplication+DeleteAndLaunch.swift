//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


extension XCUIApplication {
    /// The bundle identifier for the home screen for the specific platform.
    ///
    /// E.g., `com.apple.springboard` on iOS.
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    public static var homeScreenBundle: String {
#if os(visionOS)
        "com.apple.RealityLauncher"
#elseif os(tvOS)
        "com.apple.pineboard"
#elseif os(iOS)
        "com.apple.springboard"
#else
        preconditionFailure("Unsupported platform.")
#endif
    }
    
    private static var visionOS2: Bool {
        #if os(visionOS)
        if #available(visionOS 2.0, *) {
            true
        } else {
            false
        }
        #else
        false
        #endif
    }

    /// Deletes the application from the iOS springboard (iOS home screen) and launches it after it has been deleted and reinstalled.
    /// - Parameter appName: The name of the application as displayed on the springboard (iOS home screen).
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    public func deleteAndLaunch(withSpringboardAppName appName: String) {
        self.terminate()

        let springboard = XCUIApplication(bundleIdentifier: Self.homeScreenBundle)
        #if os(visionOS)
        springboard.launch() // springboard is in `runningBackgroundSuspended` state on visionOS. So we need to launch it not just activate
        #else
        springboard.activate()
        #endif

        if springboard.icons[appName].firstMatch.waitForExistence(timeout: 10.0) {
            if !springboard.icons[appName].firstMatch.isHittable {
                springboard.swipeLeft()
            }
            
            XCTAssertTrue(springboard.icons[appName].firstMatch.isHittable)
            springboard.icons[appName].firstMatch.press(forDuration: 1.75)
            
            if XCUIApplication.visionOS2 {
                // VisionOS 2.0 changed the behavior how apps are deleted, showing a delete button above the app icon.
                sleep(5)
                let deleteButtons = springboard.collectionViews.buttons.matching(identifier: "Delete")
                // There is no isEmtpy property on the `XCUIElementQuery`.
                // swiftlint:disable:next empty_count
                if deleteButtons.count > 0 {
                    // We assume that the latest installed app is on the trailing part of the screen and therefore also the last button.
                    let lastDeleteButton = deleteButtons.element(boundBy: deleteButtons.count - 1)
                    lastDeleteButton.tap()
                } else {
                    XCTFail("No 'Delete' buttons found")
                }
            } else {
                if !springboard.collectionViews.buttons["Remove App"].waitForExistence(timeout: 10.0) && springboard.state != .runningForeground {
                    // The long press did not work, let's launch the springboard again and then try long pressing the app icon again.
                    springboard.activate()
                    
                    sleep(2)
                    
                    XCTAssertTrue(springboard.icons[appName].firstMatch.isHittable)
                    springboard.icons[appName].firstMatch.press(forDuration: 1.75)
                    
                    XCTAssertTrue(springboard.collectionViews.buttons["Remove App"].waitForExistence(timeout: 10.0))
                }

                springboard.buttons["Remove App"].tap()
            }
            
            #if os(visionOS)
            // alerts are running in their own process on visionOS (lol). Took me literally 3 hours.
            let notifications = visionOSNotifications

            XCTAssert(notifications.staticTexts["Delete “\(appName)”?"].waitForExistence(timeout: 5.0))
            XCTAssert(notifications.buttons["Delete"].waitForExistence(timeout: 2.0))
            notifications.buttons["Delete"].tap() // currently no better way of hitting some "random" delete button.
            #else
            XCTAssertTrue(springboard.alerts["Remove “\(appName)”?"].buttons["Delete App"].waitForExistence(timeout: 10.0))
            springboard.alerts["Remove “\(appName)”?"].buttons["Delete App"].tap()
            XCTAssertTrue(springboard.alerts["Delete “\(appName)”?"].buttons["Delete"].waitForExistence(timeout: 10.0))
            springboard.alerts["Delete “\(appName)”?"].buttons["Delete"].tap()
            #endif
        }
        
        // Wait for 5 Seconds for the application to be deleted and removed.
        sleep(5)
        
        self.launch()
    }
}
