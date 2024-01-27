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
    
    
    var body: some View {
        @Bindable var viewModel = viewModel
        List {
            ForEach($viewModel.medicationInstances) { medicationInstance in
                NavigationLink {
                    EditMedication(medicationInstance: medicationInstance)
                        .environment(viewModel)
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(medicationInstance.wrappedValue.localizedDescription)
                            .font(.headline)
                        Text(medicationInstance.wrappedValue.dosage.localizedDescription)
                            .font(.subheadline)
                    }
                }
            }
                .onDelete { offsets in
                    for offset in offsets {
                        withAnimation {
                            _ = viewModel.medicationInstances.remove(at: offset)
                        }
                    }
                }
        }
    }
}
