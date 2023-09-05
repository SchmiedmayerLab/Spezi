//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

struct DismissKeyboardTest: View {
    struct SubView: View {
        @State var text = ""
        var submitLabel: SubmitLabel
        var label: String

        var body: some View {
            TextField(text: $text) {
                Text(label)
            }
                .submitLabel(submitLabel)
        }

        init(_ label: String, label submitLabel: SubmitLabel) {
            self.submitLabel = submitLabel
            self.label = label
        }
    }

    var body: some View {
        Form {
            SubView("Continue", label: .continue)
            SubView("Done", label: .done)
            SubView("Go", label: .go)
            SubView("Join", label: .join)
            SubView("Next", label: .next)
            SubView("Return", label: .return)
            SubView("Route", label: .route)
            SubView("Search", label: .search)
            SubView("Send", label: .send)
        }
    }
}

struct DismissKeyboardTest_Previews: PreviewProvider {
    static var previews: some View {
        DismissKeyboardTest()
    }
}
