//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


struct AddMedicationSchedule<MI: MedicationInstance>: View {
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel
    @Binding private var isPresented: Bool
    
    @State private var frequency: Frequency = .regularDayIntervals(1)
    @State private var times: [ScheduleTime] = []
    
    private let medicationOption: MI.InstanceType
    private let dosage: MI.InstanceDosage
    
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                titleSection
                EditFrequency(frequency: $frequency)
                EditScheduleTime(times: $times)
            }
            VStack(alignment: .center) {
                AsyncButton(
                    action: {
                        viewModel.medicationInstances.insert(
                            viewModel.createMedicationInstance(
                                medicationOption,
                                dosage,
                                Schedule(frequency: frequency, times: times)
                            )
                        )
                        isPresented = false
                    },
                    label: {
                        Text("Add Medication", bundle: .module)
                            .frame(maxWidth: .infinity, minHeight: 38)
                    }
                )
                    .buttonStyle(.borderedProminent)
            }
                .padding()
                .background {
                    Color(uiColor: .systemGroupedBackground)
                        .edgesIgnoringSafeArea(.bottom)
                }
        }
            .navigationTitle("Medication Schedule")
    }
    
    private var titleSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(alignment: .center) {
                    Image(systemName: "calendar")
                        .resizable()
                        .accessibilityHidden(true)
                        .foregroundColor(.accentColor)
                        .scaledToFit()
                        .frame(width: 70, height: 100)
                    Text("When will you take \(medicationOption.localizedDescription) (\(dosage.localizedDescription))?", bundle: .module)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                }
                Spacer()
            }
        }
    }
    
    
    init(
        medicationOption: MI.InstanceType,
        dosage: MI.InstanceDosage,
        isPresented: Binding<Bool>
    ) {
        self.medicationOption = medicationOption
        self.dosage = dosage
        self._isPresented = isPresented
    }
}
