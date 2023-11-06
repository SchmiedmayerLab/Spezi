//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct AddMedication<MI: MedicationInstance>: View {
    typealias CreateMedicationInstance = (MI.InstanceType, MI.InstanceDosage) -> MI
    
    
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel
    
    @State private var searchText = ""
    @Binding private var isPresented: Bool
    
    
    private var searchResults: [MI.InstanceType] {
        if searchText.isEmpty {
            return viewModel.medicationOptions.sorted()
        } else {
            return viewModel.medicationOptions
                .filter {
                    $0.localizedDescription.contains(searchText)
                }
                .sorted()
        }
    }
    
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(searchResults, id: \.self) { medicationOption in
                    NavigationLink {
                        AddMedicationDosage<MI>(
                            medicationOption: medicationOption,
                            isPresented: $isPresented
                        )
                    } label: {
                        Text(medicationOption.localizedDescription)
                    }
                }
            }
                .navigationTitle(String(localized: "ADD_MEDICATION", bundle: .module))
                .searchable(text: $searchText, prompt: String(localized: "SEARCH_FOR_MEDICATION", bundle: .module))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "CANCEL", bundle: .module)) {
                            isPresented = false
                        }
                    }
                }
        }
    }
    
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
}
