//
// This source file is part of the XCTestExtensions open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


/// Allows the definition of an enum of different test cases in your test application that are associated with SwiftUI views
public struct TestAppTestsView<Tests: TestAppTests>: View {
    @State private var path = NavigationPath()
    
    
    public var body: some View {
        NavigationStack(path: $path) {
            List(Array(Tests.allCases)) { test in
                NavigationLink(test.rawValue, value: test)
            }
                .navigationDestination(for: Tests.self) { test in
                    test.view(withNavigationPath: $path)
                }
                .navigationTitle(String(describing: Tests.self))
        }
    }
    
    
    /// - Parameter tests: The ``TestAppTests`` type that should be associated with the ``TestAppTestsView``
    public init(tests: Tests.Type = Tests.self) { }
}
