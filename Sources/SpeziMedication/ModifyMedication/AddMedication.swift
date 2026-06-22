//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct AddMedication<MI: MedicationInstance>: View {
    typealias CreateMedicationInstance = (MI.InstanceType, MI.InstanceDosage, Schedule) -> MI
    

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
                .navigationTitle(String(localized: "Add a Medication", bundle: .module))
                .searchable(text: $searchText, prompt: String(localized: "Search for a medication", bundle: .module))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "Cancel", bundle: .module)) {
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
