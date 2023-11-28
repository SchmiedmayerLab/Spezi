//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct EditDosage<MI: MedicationInstance>: View {
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel
    
    @Binding private var dosage: MI.InstanceDosage
    
    private let medication: MI.InstanceType
    private let initialDosage: MI.InstanceDosage?
    
    
    var body: some View {
        Picker(String(localized: "Dosage: \(medication.localizedDescription)", bundle: .module), selection: $dosage) {
            ForEach(medication.dosages, id: \.self) { dosage in
                if viewModel.duplicateOf(medication: medication, dosage: dosage) && initialDosage != dosage {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(dosage.localizedDescription)
                            Text("Medication with this dosage already exists.", bundle: .module)
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                        }
                            .foregroundStyle(Color.secondary)
                            .disabled(true)
                        Spacer()
                    }
                        .padding(.vertical, 11) // Unfortunate workaround as we can not disable touch in Pickers.
                        .padding(.horizontal, 100)
                        .contentShape(Rectangle())
                        .onTapGesture {}
                        .padding(.vertical, -11)
                        .padding(.horizontal, -100)
                } else {
                    Text(dosage.localizedDescription)
                        .tag(dosage)
                }
            }
        }
            .pickerStyle(.inline)
            .accessibilityIdentifier(String(localized: "Dosage Picker", bundle: .module))
    }
    
    
    init(dosage: Binding<MI.InstanceDosage>, medication: MI.InstanceType, initialDosage: MI.InstanceDosage) {
        self._dosage = dosage
        self.medication = medication
        self.initialDosage = initialDosage
    }
    
    init(dosage: Binding<MI.InstanceDosage>, medication: MI.InstanceType) {
        self._dosage = dosage
        self.medication = medication
        self.initialDosage = nil
    }
}
