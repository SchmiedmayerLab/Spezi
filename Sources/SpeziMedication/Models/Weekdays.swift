//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


public struct Weekdays: OptionSet, Codable, Hashable, CaseIterable, Identifiable {
    public static var allCases: [Weekdays] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    
    static let sunday = Weekdays(rawValue: 1 << 0)
    static let monday = Weekdays(rawValue: 1 << 1)
    static let tuesday = Weekdays(rawValue: 1 << 2)
    static let wednesday = Weekdays(rawValue: 1 << 3)
    static let thursday = Weekdays(rawValue: 1 << 4)
    static let friday = Weekdays(rawValue: 1 << 5)
    static let saturday = Weekdays(rawValue: 1 << 6)
    
    static let all = Weekdays(allCases)
    static let weekend: Weekdays = [.saturday, .sunday]
    
    
    public let rawValue: UInt8
    
    
    public var id: RawValue {
        rawValue
    }
    
    public var localizedDescription: String {
        guard let weekdays = DateFormatter().weekdaySymbols else {
            return ""
        }
        
        return descriptionFrom(weekdayDescriptions: weekdays)
    }
    
    public var localizedShortDescription: String {
        guard let weekdays = DateFormatter().shortWeekdaySymbols else {
            return ""
        }
        
        return descriptionFrom(weekdayDescriptions: weekdays)
    }
    
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    
    private func descriptionFrom(weekdayDescriptions: [String]) -> String {
        if self == .all {
            return String(localized: "Every Day", bundle: .module)
        }
        
        if self == .weekend {
            return String(localized: "Weekend", bundle: .module)
        }
        
        guard weekdayDescriptions.count >= 7 else {
            return ""
        }
        
        var descriptions = [String]()
        
        if contains(.sunday) {
            descriptions.append(weekdayDescriptions[0])
        }
        if contains(.monday) {
            descriptions.append(weekdayDescriptions[1])
        }
        if contains(.tuesday) {
            descriptions.append(weekdayDescriptions[2])
        }
        if contains(.wednesday) {
            descriptions.append(weekdayDescriptions[3])
        }
        if contains(.thursday) {
            descriptions.append(weekdayDescriptions[4])
        }
        if contains(.friday) {
            descriptions.append(weekdayDescriptions[5])
        }
        if contains(.saturday) {
            descriptions.append(weekdayDescriptions[6])
        }
        
        return descriptions.joined(separator: ", ")
    }
}
