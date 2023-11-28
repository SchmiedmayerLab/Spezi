//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


public struct ScheduleTime: Codable, Identifiable, Hashable, Equatable, Comparable {
    public let uuid: UUID
    public let time: DateComponents
    
    
    public var id: String {
        "\(time.hour ?? 0):\(time.minute ?? 0)"
    }
    
    var date: Date {
        Calendar.current.date(bySettingHour: self.time.hour ?? 0, minute: self.time.minute ?? 0, second: 0, of: .now) ?? .now
    }
    
    
    init(time: DateComponents) {
        precondition(time.hour != nil && time.minute != nil)
        
        self.uuid = UUID()
        self.time = time
    }
    
    init(date: Date) {
        self.init(time: Calendar.current.dateComponents([.hour, .minute], from: date))
    }
    
    
    public static func == (lhs: ScheduleTime, rhs: ScheduleTime) -> Bool {
        lhs.time.hour == rhs.time.hour && lhs.time.minute == rhs.time.minute
    }
    
    public static func < (lhs: ScheduleTime, rhs: ScheduleTime) -> Bool {
        guard lhs.time.hour == rhs.time.hour else {
            return lhs.time.hour ?? 0 < rhs.time.hour ?? 0
        }
        
        return lhs.time.minute ?? 0 < rhs.time.minute ?? 0
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
