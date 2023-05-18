//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct XCTestExentionsTest: View {
    @State var text: String = ""
    @State var secureText: String = ""
    
    
    var body: some View {
        Form {
            Section {
                TextField("TextField", text: $text)
                Text(text.isEmpty ? "No text set ..." : text)
            }
            Section {
                SecureField("SecureField", text: $secureText)
                Text(secureText.isEmpty ? "No secure text set ..." : secureText)
            }
        }
    }
}
