//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziMedication
import SwiftUI


@Observable
class ExampleMedicationSettingsViewModel: Module, MedicationSettingsViewModel, CustomStringConvertible {
    var medicationInstances: Set<ExampleMedicationInstance> = []
    let medicationOptions: Set<ExampleMedication>
    
    
    var description: String {
        guard !medicationInstances.isEmpty else {
            return "No Medications"
        }
        
        return medicationInstances
            .map { medicationInstance in
                let scheduleDescription: String
                switch medicationInstance.schedule.frequency {
                case let .regularDayIntervals(dayInterval):
                    scheduleDescription = "RegularDayIntervals: \(dayInterval)"
                case let .specificDaysOfWeek(weekdays):
                    scheduleDescription = "SpecificDaysOfWeek: \(weekdays)"
                case .asNeeded:
                    scheduleDescription = "AsNeeded"
                }
                
                return "\(medicationInstance.localizedDescription) - \(medicationInstance.dosage.localizedDescription) - \(scheduleDescription)"
            }
            .joined(separator: ", ")
    }
    
    
    init() {
        self.medicationOptions = [
            ExampleMedication(
                localizedDescription: "Medication 1",
                dosages: [
                    ExampleDosage(localizedDescription: "Dosage 1.1"),
                    ExampleDosage(localizedDescription: "Dosage 1.2"),
                    ExampleDosage(localizedDescription: "Dosage 1.3")
                ]
            ),
            ExampleMedication(
                localizedDescription: "Medication 2",
                dosages: [
                    ExampleDosage(localizedDescription: "Dosage 2.1")
                ]
            ),
            ExampleMedication(
                localizedDescription: "Medication 3",
                dosages: [
                    ExampleDosage(localizedDescription: "Dosage 3.1"),
                    ExampleDosage(localizedDescription: "Dosage 3.2")
                ]
            )
        ]
    }
    
    
    func persist(medicationInstances: Set<ExampleMedicationInstance>) async throws {
        try await Task.sleep(for: .seconds(2))
        self.medicationInstances = medicationInstances
    }
}
