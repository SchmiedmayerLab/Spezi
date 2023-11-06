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
                EditDosageSection<MI>(dosage: $dosage, medication: medicationOption)
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
                Text("ADD_MEDICATION_DUPLICATE", bundle: .module)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            AsyncButton(
                action: {
                    viewModel.medicationInstances.insert(viewModel.createMedicationInstance(medicationOption, dosage))
                    isPresented = false
                },
                label: {
                    Text("ADD_MEDICATION_TITLE", bundle: .module)
                        .frame(maxWidth: .infinity, minHeight: 38)
                }
            )
                .buttonStyle(.borderedProminent)
        }
            .disabled(isDuplicate)
            .padding()
            .background {
                Color(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea(.bottom)
            }
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
