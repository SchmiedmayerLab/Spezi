//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Dosage of a medication.
///
/// Defines the dosage of a ``MedicationInstance`` as a subset of the ``Medication/dosages`` of a ``Medication``.
public protocol Dosage: Codable, Hashable {
    /// Localized description of the dosage.
    var localizedDescription: String { get }
}
