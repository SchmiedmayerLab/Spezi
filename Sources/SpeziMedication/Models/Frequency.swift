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
    
    
    enum CodingKeys: CodingKey {
        case regularDayIntervals
        case specificDaysOfWeek
        case asNeeded
    }
    
    
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
    
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var allKeys = ArraySlice(container.allKeys)
        
        guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
            throw DecodingError.typeMismatch(
                Frequency.self,
                DecodingError.Context.init(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid number of keys found, expected one.",
                    underlyingError: nil
                )
            )
        }
        
        switch onlyKey {
        case .regularDayIntervals:
            self = Frequency.regularDayIntervals(try container.decode(Int.self, forKey: CodingKeys.regularDayIntervals))
        case .specificDaysOfWeek:
            self = Frequency.specificDaysOfWeek(try container.decode(Weekdays.self, forKey: CodingKeys.specificDaysOfWeek))
        case .asNeeded:
            self = Frequency.asNeeded
        }
    }
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .regularDayIntervals(dayInterval):
            try container.encode(dayInterval, forKey: .regularDayIntervals)
        case let .specificDaysOfWeek(weekdays):
            try container.encode(weekdays, forKey: .specificDaysOfWeek)
        case .asNeeded:
            try container.encode(true, forKey: .asNeeded)
        }
    }
}
