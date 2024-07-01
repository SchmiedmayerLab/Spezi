//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SwiftUI


@main
struct UITestsApp: App {
    @ApplicationDelegateAdaptor(TestAppDelegate.self) var appDelegate
    
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MenuView()
            }
            .spezi(appDelegate)
        }
    }
}

struct MenuView: View {
    var body: some View {
        List {
            NavigationLink(destination: SpeechTestView()) {
                Text("Speech Test View")
            }
            NavigationLink(destination: SpeechVoiceSelectionTestView()) {
                Text("Speech Voice Selection Test View")
            }
        }
        .navigationTitle("Spezi Speech Tests")
    }
}
