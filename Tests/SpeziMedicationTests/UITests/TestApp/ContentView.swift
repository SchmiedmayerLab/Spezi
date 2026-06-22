//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziMedication
import SwiftUI


struct ContentView: View {
    @State private var presentSettings = false
    private var medicationSettingsViewModel = ExampleMedicationSettingsViewModel()
    
    
    var body: some View {
        VStack {
            Button("Show Settings") {
                presentSettings.toggle()
            }
            Text(medicationSettingsViewModel.description)
        }
            .sheet(isPresented: $presentSettings) {
                NavigationStack {
                    MedicationSettings(isPresented: $presentSettings, medicationSettingsViewModel: medicationSettingsViewModel)
                        .navigationTitle("Medication Settings")
                }
            }
    }
}

#Preview {
    ContentView()
}
