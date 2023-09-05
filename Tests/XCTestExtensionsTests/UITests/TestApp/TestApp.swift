//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI
import XCTestApp


@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            TestAppTestsView(tests: TestAppTestCaseEnum.self)
        }
    }
}
