//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziConsent
import SpeziOnboarding
import SpeziViews
import SwiftUI
import UIKit


struct RenderedConsentDocumentView: View {
    let docId: ConsentDocumentIdentifier
    
    @Environment(\.dismiss) private var dismiss
    @Environment(ManagedNavigationStack.Path.self) private var path: ManagedNavigationStack.Path?
    @Environment(TestAppConsentStorage.self) private var consentStorage
    @State private var exportResult: ConsentDocument.ExportResult?
    
    var body: some View {
        Form { // swiftlint:disable:this closure_body_length
            if let exportResult, exportResult.pdf.pageCount > 0 {
                Label {
                    Text("\(docId.title) PDF rendering exists")
                } icon: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                }
                if !exportResult.userResponses.toggles.isEmpty {
                    Section("Toggles") {
                        ForEach(Array(exportResult.userResponses.toggles.keys), id: \.self) { toggleId in
                            let value = exportResult.userResponses.toggles[toggleId]! // swiftlint:disable:this force_unwrapping
                            LabeledContent(toggleId, value: value.description)
                        }
                    }
                }
                if !exportResult.userResponses.selects.isEmpty {
                    Section("Selects") {
                        ForEach(Array(exportResult.userResponses.selects.keys), id: \.self) { selectId in
                            let value = exportResult.userResponses.selects[selectId]! // swiftlint:disable:this force_unwrapping
                            LabeledContent(selectId, value: value)
                        }
                    }
                }
                if !exportResult.userResponses.signatures.isEmpty {
                    ForEach(Array(exportResult.userResponses.signatures.keys), id: \.self) { (signatureId: String) in
                        Section("Signature: '\(signatureId)'") {
                            let value = exportResult.userResponses.signatures[signatureId]! // swiftlint:disable:this force_unwrapping
                            LabeledContent("Name", value: value.name.formatted())
                            LabeledContent("Signature") {
                                #if os(iOS)
                                let scale: CGFloat = UIScreen.main.scale
                                #else
                                let scale: CGFloat = 3
                                #endif
                                let image = value.signature.image(from: value.signature.bounds, scale: scale)
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 200)
                                    .accessibilityLabel("Signature Drawing")
                            }
                        }
                    }
                }
            } else {
                Label {
                    Text("\(docId.title) PDF rendering doesn't exist")
                } icon: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.red)
                        .accessibilityHidden(true)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Next") {
                    if path?.nextStep() != true { // will be `nil` if there is no path, or `false` if we're at the end.
                        dismiss()
                    }
                }
                .bold()
            }
        }
        .navigationTitle("Consent Export Result")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            // Read and then clean up the respective exported consent document from the `ExampleStandard`
            exportResult = consentStorage.exportResults[docId].take()
        }
    }
}
