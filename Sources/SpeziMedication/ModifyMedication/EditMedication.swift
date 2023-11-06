//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


struct EditMedication<MI: MedicationInstance>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel
    
    @State private var dosage: MI.InstanceDosage
    
    private let medicationInstanceId: MI.ID
    
    private var medicationInstance: MI? {
        viewModel.medicationInstances.first(where: { $0.id == medicationInstanceId })
    }
    
    
    var body: some View {
        if let medicationInstance {
            VStack {
                Form {
                    EditDosageSection<MI>(dosage: $dosage, medication: medicationInstance.type, initialDosage: dosage)
                    Section {
                        Button(String(localized: "DELETE_MEDICATION", bundle: .module), role: .destructive) {
                            viewModel.medicationInstances.remove(medicationInstance)
                            dismiss()
                        }
                    }
                }
            }
                .navigationTitle(medicationInstance.localizedDescription)
                .onChange(of: dosage) {
                    guard medicationInstance.dosage != dosage else {
                        return
                    }
                    
                    viewModel.medicationInstances.remove(medicationInstance)
                    
                    var modifiedMedication = medicationInstance
                    modifiedMedication.dosage = dosage
                    
                    viewModel.medicationInstances.insert(modifiedMedication)
                }
        } else {
            ProgressView()
        }
    }
    
    
    init(
        medicationInstance medicationInstanceId: MI.ID,
        initialDosage: MI.InstanceDosage
    ) {
        self.medicationInstanceId = medicationInstanceId
        self._dosage = State(initialValue: initialDosage)
    }
}
