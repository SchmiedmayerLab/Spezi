//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI
import XCTestApp


enum TestAppTestCaseEnum: String, TestAppTests {
    case xcTestApp = "XCTestApp"
    case xcTestExtensions = "XCTestExtensions"
    case dismissKeyboard = "DismissKeyboard"
    
    
    func view(withNavigationPath path: Binding<NavigationPath>) -> some View {
        switch self {
        case .xcTestApp:
            TestAppView(testCase: XCTestAppTestCaseTest())
        case .xcTestExtensions:
            XCTestExtensionsTest()
        case .dismissKeyboard:
            DismissKeyboardTest()
        }
    }
}
