//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Schedule of a medication.
public struct Schedule: Codable, Equatable, Hashable {
    enum CodingKeys: CodingKey {
        case frequency
        case times
        case startDate
    }
    
    
    /// The frequency of the Schedule, see ``Frequency`.`.
    public var frequency: Frequency
    /// The times of the Schedule, that are associated with the ``Schedule/frequency`.`.
    public var times: [ScheduledTime]
    /// Start date of the schedule.
    public var startDate: Date
    
    
    /// - Parameters:
    ///   - frequency: The frequency of the Schedule, see ``Frequency`.`
    ///   - times: The times of the Schedule, that are associated with the ``Schedule/frequency`.`
    public init(frequency: Frequency = .asNeeded, times: [ScheduledTime] = [], startDate: Date = .now) {
        self.frequency = frequency
        self.times = times
        self.startDate = startDate
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.frequency = try container.decode(Frequency.self, forKey: .frequency)
        self.times = try container.decodeIfPresent([ScheduledTime].self, forKey: .times) ?? []
        self.startDate = try container.decode(Date.self, forKey: .startDate)
    }
    
    
    /// See Equatable
    public static func == (lhs: Schedule, rhs: Schedule) -> Bool {
        lhs.frequency == rhs.frequency && lhs.times.sorted() == rhs.times.sorted() && lhs.startDate == rhs.startDate
    }
    
    
    public func timesScheduled(onDay date: Date = .now) -> [Date] {
        switch frequency {
        case let .regularDayIntervals(dayInterval):
            guard let dayDifference = Calendar.current.dateComponents([.day], from: startDate, to: date).day,
                  dayDifference.isMultiple(of: dayInterval) else {
                return []
            }
        case let .specificDaysOfWeek(weekdays):
            guard let weekday = Weekdays(weekDay: Calendar.current.component(.weekday, from: date)),
                  weekdays.contains(weekday) else {
                return []
            }
        case .asNeeded:
            break
        }
        
        return times.compactMap { scheduledTime -> Date? in
            guard let hour = scheduledTime.time.hour, let minute = scheduledTime.time.minute else {
                return nil
            }
            
            return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date)
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(frequency)
        hasher.combine(times.sorted())
        hasher.combine(startDate)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.frequency, forKey: .frequency)
        if !times.isEmpty {
            try container.encode(self.times, forKey: .times)
        }
        try container.encode(self.startDate, forKey: .startDate)
    }
}
