//
// This source file is part of the SpeziNotifications open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziNotifications
import SwiftUI
import XCTSpeziNotificationsUI


@main
struct UITestsApp: App {
    @UIApplicationDelegateAdaptor(TestAppDelegate.self)
    private var appDelegate

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Controls", systemImage: "switch.2") {
                    NavigationStack {
                        ControlsView()
                    }
                }

                Tab("Notifications", systemImage: "mail") {
                    NavigationStack {
                        NotificationsView()
                    }
                }
            }
                .spezi(appDelegate)
        }
    }
}
