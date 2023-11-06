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
    
    
    var localizedDescription: String {
        type.localizedDescription
    }
    
    
    init(type: ExampleMedication, dosage: ExampleDosage) {
        self.id = UUID()
        self.type = type
        self.dosage = dosage
    }
    
    
    static func < (lhs: ExampleMedicationInstance, rhs: ExampleMedicationInstance) -> Bool {
        lhs.localizedDescription < rhs.localizedDescription
    }
}
