//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct EditScheduleTime: View {
    // We assume that a user doesn't take a single medication more than the number of possible times which are 12 * 24 for 5 minute intervals.
    private static let maxTimesCount = (60 / ScheduledTimeDatePicker.minuteInterval) * 24
    
    @Binding private var times: [ScheduledTime]
    
    private let numberOfDosageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    
    var body: some View {
        Section {
            if !times.isEmpty {
                timesList
            }
            if times.count < Self.maxTimesCount {
                addTimeButton
            }
        }
            .onChange(of: times, initial: true) {
                withAnimation {
                    times.sort()
                }
            }
    }
    
    
    private var timesList: some View {
        List($times) { $time in
            EditScheduleTimeRow(time: $time, times: $times, excludedDates: times.map(\.date))
        }
    }
    
    private var addTimeButton: some View {
        Button(
            action: {
                addNewTime()
            },
            label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .accessibilityHidden(true)
                        .foregroundStyle(Color.green)
                    Text("Add a time")
                }
            }
        )
    }
    
    
    init(times: Binding<[ScheduledTime]>) {
        self._times = times
    }
    
    
    private func addNewTime() {
        var endlessLoopCounter = 0
        let possibleNewTime = times.last?.time.date?.addingTimeInterval(Double(ScheduledTimeDatePicker.minuteInterval) * 60) ?? Date.now
        let possibleNewTimeMinute = Calendar.current.dateComponents([.minute], from: possibleNewTime)
        
        guard var newTimeAdded = Calendar.current.date(
            bySetting: .minute,
            value: ((possibleNewTimeMinute.minute ?? 0) / 5) * 5,
            of: possibleNewTime
        ) else {
            return
        }
        
        while endlessLoopCounter <= Self.maxTimesCount {
            let newScheduleTime = ScheduledTime(date: newTimeAdded)
            
            guard !times.contains(newScheduleTime) else {
                newTimeAdded.addTimeInterval(Double(ScheduledTimeDatePicker.minuteInterval) * 60)
                endlessLoopCounter += 1
                continue
            }
            
            times.append(newScheduleTime)
            return
        }
    }
}
