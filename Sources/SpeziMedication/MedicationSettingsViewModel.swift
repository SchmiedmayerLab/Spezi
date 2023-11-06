//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Observation


/// Defines a unified interface to provide data and functionality of the ``MedicationSettings``
///
/// The implementation needs to provide functionalities to manage medication instances and options and persist the medications.
public protocol MedicationSettingsViewModel<Medications> {
    /// The ``MedicationInstance`` type that the ``MedicationSettingsViewModel`` implementation supports.
    associatedtype Medications: MedicationInstance
    
    /// Medication instances managed by the ``MedicationSettings`` view.
    ///
    /// This property should be updated at the end of ``persist(medicationInstances:)`` after the instances have been successfully processed to ensure that the UI and state are kept in sync.
    var medicationInstances: Set<Medications> { get }
    
    /// Represents the set of medication options available to be created.
    var medicationOptions: Set<Medications.InstanceType> { get }
    
    /// Lightweight function to create a concrete medication instance with the provided type and dosage.
    ///
    /// This function should **not** be used to persist any chances. It can be called multiple times and should be lightweight.
    ///
    /// If the ``MedicationInstance`` conforms to ``MedicationInstanceInitializable`` this function is providing a default implementation.
    /// - Parameters:
    ///  - type: The type of the medication instance to be created.
    ///  - dosage: The dosage of the medication instance.
    /// - Returns: A new medication instance.
    func createMedicationInstance(withType type: Medications.InstanceType, dosage: Medications.InstanceDosage) -> Medications
    
    /// Persists a set of medication instances.
    ///
    /// Use this function to persist all changes or throw a `LocalizableError` in case an error occurs.
    ///
    /// Be sure that the ``medicationInstances`` property is updated with the resulting set of medications.
    /// - Parameter medications: The set of medications to be persisted.
    func persist(medicationInstances: Set<Medications>) async throws
}


extension MedicationSettingsViewModel where Medications: MedicationInstanceInitializable {
    // Swiftlint does unfortunately not pick up on the documentation as we override a protocol requirement.
    // swiftlint:disable:next missing_docs
    public func createMedicationInstance(withType type: Medications.InstanceType, dosage: Medications.InstanceDosage) -> Medications {
        Medications(type: type, dosage: dosage)
    }
}
