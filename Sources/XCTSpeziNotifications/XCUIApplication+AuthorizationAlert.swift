//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziNotifications
import UserNotifications
import XCTest


extension XCUIApplication {
    /// Action of the notification authorization alert.
    public enum NotificationAuthorizationAction: String {
        case allow = "Allow"
        case doNotAllow = "Don’t Allow"
    }
    
    /// Confirm the notification authorization dialog.
    /// - Parameter action: The action to confirm the alert with.
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    public func confirmNotificationAuthorization(action: NotificationAuthorizationAction = .allow) {
        let predicate = NSPredicate(format: "label CONTAINS 'Would Like to Send You Notifications'")

#if os(iOS)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.element(matching: predicate)
        XCTAssert(alert.waitForExistence(timeout: 5.0))
        XCTAssert(alert.buttons[action.rawValue].exists)
        alert.buttons[action.rawValue].tap()
#elseif os(visionOS)
        let notifications = XCUIApplication(bundleIdentifier: "com.apple.RealityNotifications")
        XCTAssert(notifications.scrollViews.staticTexts.element(matching: predicate).waitForExistence(timeout: 5.0))
        XCTAssert(notifications.buttons[action.rawValue].exists)
        notifications.buttons[action.rawValue].tap()
#else
        preconditionFailure("Unsupported platform")
#endif
    }
}
