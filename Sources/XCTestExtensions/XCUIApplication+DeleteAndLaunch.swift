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
        self.delete(app: appName)
        self.launch()
    }
    
    /// Delete the application from the home screen.
    ///
    /// Deletes the application from the iOS Springboard, visionOS RealityLauncher or tvOS Pineboard.
    /// - Parameter appName: The springboard name of the application.
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    public func delete(app appName: String) {
        self.terminate()

        let springboard = XCUIApplication(bundleIdentifier: Self.homeScreenBundle)
#if os(visionOS)
        springboard.launch() // springboard is in `runningBackgroundSuspended` state on visionOS. So we need to launch it not just activate
#else
        springboard.activate()
#endif

        // There might be multiple apps installed with the same name (e.g., we use "TestApp" a lot), so delete all of them
        while springboard.icons[appName].firstMatch.waitForExistence(timeout: 10.0) {
            if !springboard.icons[appName].firstMatch.isHittable {
                springboard.swipeLeft()
            }

            XCTAssertTrue(springboard.icons[appName].firstMatch.isHittable)
#if os(visionOS)
            springboard.icons[appName].firstMatch.press(forDuration: 1)
#else
            springboard.icons[appName].firstMatch.press(forDuration: 1.5)
#endif

            if XCUIApplication.visionOS2 {
                // VisionOS 2.0 changed the behavior how apps are deleted, showing a delete button above the app icon.
                let deleteButton = springboard.icons[appName].buttons["Delete"]

                XCTAssertTrue(deleteButton.waitForExistence(timeout: 5.0))
                deleteButton.tap()
            } else {
                if !springboard.collectionViews.buttons["Remove App"].waitForExistence(timeout: 10.0) && springboard.state != .runningForeground {
                    // The long press did not work, let's launch the springboard again and then try long pressing the app icon again.
                    springboard.activate()

                    XCTAssert(springboard.wait(for: .runningForeground, timeout: 2.0))

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

            // If the app had health data stored, deleting the app will show an alert, which we need to dismiss.
            // We also use this check to provide a 5 second timeout for the app to be deleted.
            let alertTitle = "There is data from “\(appName)” saved in Health"
            if springboard.alerts[alertTitle].waitForExistence(timeout: 5.0) {
                springboard.alerts[alertTitle].buttons["OK"].tap()
            }
            
            // Exit the while loop early without a `springboard.icons[appName].firstMatch.waitForExistence(timeout: 10.0)` call.
            // If the app takes longer to be deleted, this will give it some more time.
            // Only leads to a delay if we have to delete multiple apps with the same name; otherwise, it exits as soon as the app is removed or even immediately.
            if springboard.icons[appName].waitForNonExistence(timeout: 10.0) {
                break
            }
        }
    }
}
