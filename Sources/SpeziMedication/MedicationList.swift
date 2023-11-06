//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct MedicationList<MI: MedicationInstance>: View {
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel
    
    
    private var description: String {
        guard !viewModel.medicationInstances.isEmpty else {
            return "No Medications"
        }
        
        return viewModel.medicationInstances
            .map { medicationInstance in
                "\(medicationInstance.localizedDescription) - \(medicationInstance.dosage.localizedDescription)"
            }
            .joined(separator: ", ")
    }
    
    private var sortedMedicationInstances: [MI] {
        print(description)
        return Array(viewModel.medicationInstances).sorted()
    }
    
    
    var body: some View {
        List {
            ForEach(sortedMedicationInstances) { medicationInstance in
                NavigationLink {
                    EditMedication<MI>(
                        medicationInstance: medicationInstance.id,
                        initialDosage: medicationInstance.dosage
                    )
                        .environment(viewModel)
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(medicationInstance.localizedDescription)
                            .font(.headline)
                        Text(medicationInstance.dosage.localizedDescription)
                            .font(.subheadline)
                    }
                }
            }
                .onDelete { offsets in
                    for offset in offsets {
                        viewModel.medicationInstances.remove(sortedMedicationInstances[offset])
                    }
                }
        }
    }
}
