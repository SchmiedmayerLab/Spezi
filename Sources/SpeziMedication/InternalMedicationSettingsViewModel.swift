//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Observation


@Observable
class InternalMedicationSettingsViewModel<MI: MedicationInstance> {
    var medicationInstances: Set<MI>
    let medicationOptions: Set<MI.InstanceType>
    let createMedicationInstance: AddMedication<MI>.CreateMedicationInstance
    
    
    init(
        medicationInstances: Set<MI>,
        medicationOptions: Set<MI.InstanceType>,
        createMedicationInstance: @escaping AddMedication<MI>.CreateMedicationInstance
    ) {
        self.medicationInstances = medicationInstances
        self.medicationOptions = medicationOptions
        self.createMedicationInstance = createMedicationInstance
    }
    
    
    func duplicateOf(medication: MI.InstanceType, dosage: MI.InstanceDosage) -> Bool {
        medicationInstances.contains(where: { $0.type == medication && $0.dosage == dosage })
    }
}


extension MedicationSettingsViewModel {
    var internalViewModel: InternalMedicationSettingsViewModel<Medications> {
        InternalMedicationSettingsViewModel(
            medicationInstances: medicationInstances,
            medicationOptions: medicationOptions,
            createMedicationInstance: createMedicationInstance
        )
    }
}
