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
    
    @Binding private var medicationInstance: MI
    
    
    var body: some View {
        VStack {
            Form {
                Section(String(localized: "Dosage", bundle: .module)) {
                    EditDosage<MI>(dosage: $medicationInstance.dosage, medication: medicationInstance.type, initialDosage: medicationInstance.dosage)
                        .labelsHidden()
                }
                Section(String(localized: "Schedule", bundle: .module)) {
                    EditFrequency(frequency: $medicationInstance.schedule.frequency, startDate: $medicationInstance.schedule.startDate)
                }
                Section(String(localized: "Schedule Times", bundle: .module)) {
                    EditScheduleTime(times: $medicationInstance.schedule.times)
                }
                Section {
                    Button(String(localized: "Delete", bundle: .module), role: .destructive) {
                        let id = medicationInstance.id
                        viewModel.medicationInstances.removeAll(where: { $0.id == id })
                        dismiss()
                    }
                }
            }
        }
            .navigationTitle(medicationInstance.localizedDescription)
    }
    
    
    init(medicationInstance: Binding<MI>) {
        self._medicationInstance = medicationInstance
    }
}
