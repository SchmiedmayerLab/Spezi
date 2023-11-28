//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Instance of a ``Medication``.
///
/// The ``MedicationInstance``'s identifier (`id`) must be stable across chances to the dosage and therefore should not be derived from a combination of values including the dosage.
public protocol MedicationInstance: Codable, Identifiable, Comparable, Hashable where InstanceType.MedicationDosage == InstanceDosage {
    /// Associated dosage.
    associatedtype InstanceDosage: Dosage
    /// Associated medication type.
    associatedtype InstanceType: Medication
    
    
    /// Localized description of the medication dosage.
    var localizedDescription: String { get }
    /// Type of the medication instance.
    var type: InstanceType { get }
    /// Dosage of the medication instance.
    var dosage: InstanceDosage { get set }
    /// Schedule of the medication.
    var schedule: Schedule { get set }
}


extension MedicationInstance {
    var localizedDescription: String {
        type.localizedDescription
    }
}


extension MedicationInstance {
    /// See Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type && lhs.dosage == rhs.dosage
    }
}
