//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


struct AddMedicationDosage<MI: MedicationInstance>: View {
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel
    
    @State private var dosage: MI.InstanceDosage
    @Binding private var isPresented: Bool
    
    private let medicationOption: MI.InstanceType
    
    
    private var isDuplicate: Bool {
        viewModel.duplicateOf(medication: medicationOption, dosage: dosage)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    EditDosage<MI>(dosage: $dosage, medication: medicationOption)
                }
            }
            actionSection
        }
            .navigationTitle(medicationOption.localizedDescription)
            .onAppear {
                if let nonUsedDosage = medicationOption.dosages.first(where: {
                    !viewModel.duplicateOf(medication: medicationOption, dosage: $0)
                }) {
                    self.dosage = nonUsedDosage
                }
            }
    }
    
    @MainActor @ViewBuilder private var actionSection: some View {
        VStack(alignment: .center) {
            if isDuplicate {
                Text("Medication with this dosage already exists.", bundle: .module)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            addMedicationSaveDosageButton
        }
            .disabled(isDuplicate)
            .padding()
            .background {
                Color(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .navigationTitle(medicationOption.localizedDescription)
    }
    
    private var addMedicationSaveDosageButton: some View {
        NavigationLink(
            destination: {
                AddMedicationSchedule<MI>(
                    medicationOption: medicationOption,
                    dosage: dosage,
                    isPresented: $isPresented
                )
            },
            label: {
                Text("Save Dosage", bundle: .module)
                    .frame(maxWidth: .infinity, minHeight: 38)
            }
        )
        .buttonStyle(.borderedProminent)
    }
    
    
    init(medicationOption: MI.InstanceType, isPresented: Binding<Bool>) {
        self.medicationOption = medicationOption
        self._isPresented = isPresented
        
        guard let initialDosage = medicationOption.dosages.first else {
            fatalError("No dosage options for the medication: \(medicationOption)")
        }
        self._dosage = State(initialValue: initialDosage)
    }
}
