//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Marks a ``MedicationInstance`` as being initiailzable using ``MedicationInstanceInitializable/init(type:dosage:)``.
public protocol MedicationInstanceInitializable: MedicationInstance {
    /// - Parameters:
    ///   - type: Type of the medication.
    ///   - dosage: Dosage of the medication.
    init(type: InstanceType, dosage: InstanceDosage)
}
