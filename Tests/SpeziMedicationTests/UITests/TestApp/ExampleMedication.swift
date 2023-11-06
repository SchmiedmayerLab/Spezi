//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziMedication


struct ExampleMedication: Medication, Comparable {
    var localizedDescription: String
    var dosages: [ExampleDosage]
    
    
    static func < (lhs: ExampleMedication, rhs: ExampleMedication) -> Bool {
        lhs.localizedDescription < rhs.localizedDescription
    }
}
