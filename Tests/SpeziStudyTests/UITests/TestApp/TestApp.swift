//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziFoundation
import SpeziStudy
import SwiftUI
import UniformTypeIdentifiers


@main
struct UITestsApp: App {
    @UIApplicationDelegateAdaptor(TestAppDelegate.self)
    private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Home", systemImage: "house") {
                    HomeTab()
                        .injectingCustomTaskCategoryAppearances()
                }
            }
            .spezi(appDelegate)
            .onAppear {
                let fileManager = FileManager.default
                let studyBundles = ((try? fileManager.contents(of: .temporaryDirectory)) ?? [])
                    .filter { $0.pathExtension == UTType.speziStudyBundle.preferredFilenameExtension }
                for url in studyBundles {
                    try? fileManager.removeItem(at: url)
                }
            }
        }
    }
}
