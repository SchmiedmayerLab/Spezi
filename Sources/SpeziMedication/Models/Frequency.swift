//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Defines the frequency of a schedule.
public enum Frequency: Codable, CustomStringConvertible, Equatable, Hashable {
    case regularDayIntervals(Int)
    case specificDaysOfWeek(Weekdays)
    case asNeeded
    
    
    public var description: String {
        switch self {
        case let .regularDayIntervals(dayInterval):
            switch dayInterval {
            case 1:
                String(localized: "Every Day", bundle: .module)
            case 2:
                String(localized: "Every other Day", bundle: .module)
            default:
                String(localized: "Every \(dayInterval) days", bundle: .module)
            }
        case let .specificDaysOfWeek(weekdays):
            weekdays.localizedShortDescription
        case .asNeeded:
            String(localized: "As Needed", bundle: .module)
        }
    }
}
