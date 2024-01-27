//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziMedication


struct ExampleMedicationInstance: MedicationInstance, MedicationInstanceInitializable {
    let id: UUID
    let type: ExampleMedication
    var dosage: ExampleDosage
    var schedule: Schedule
    
    
    init(type: ExampleMedication, dosage: ExampleDosage, schedule: Schedule) {
        self.id = UUID()
        self.type = type
        self.dosage = dosage
        self.schedule = schedule
    }
}
