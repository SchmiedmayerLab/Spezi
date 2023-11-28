//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Schedule of a medication.
public struct Schedule: Codable, Equatable {
    /// The frequency of the Schedule, see ``Frequency`.`
    public var frequency: Frequency
    /// The times of the Schedule, that are associated with the ``Schedule/frequency`.`
    public var times: [ScheduleTime]
    
    
    /// - Parameters:
    ///   - frequency: The frequency of the Schedule, see ``Frequency`.`
    ///   - times: The times of the Schedule, that are associated with the ``Schedule/frequency`.`
    init(frequency: Frequency, times: [ScheduleTime]) {
        self.frequency = frequency
        self.times = times
    }
}
