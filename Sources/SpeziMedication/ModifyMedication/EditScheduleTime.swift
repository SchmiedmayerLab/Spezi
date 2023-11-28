//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct EditScheduleTime: View {
    @Binding private var times: [ScheduleTime]
    
    
    var body: some View {
        Section {
            List {
                ForEach(times.sorted()) { time in
                    HStack {
                        Button(
                            action: {
                                times.removeAll(where: { $0 == time })
                            },
                            label: {
                                Image(systemName: "minus.circle.fill")
                                    .accessibilityLabel(Text("Delete", bundle: .module))
                                    .foregroundStyle(Color.red)
                            }
                        )
                        DatePicker(
                            "Time",
                            selection: dateBinding(time: time),
                            displayedComponents: .hourAndMinute
                        )
                            .labelsHidden()
                    }
                }
            }
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
    }
    
    
    init(times: Binding<[ScheduleTime]>) {
        self._times = times
    }
    
    
    private func dateBinding(time: ScheduleTime) -> Binding<Date> {
        Binding(
            get: {
                time.date
            },
            set: { newValue in
                times.removeAll(where: { $0 == time })
                let newScheduleTime = ScheduleTime(date: newValue)
                
                guard !times.contains(newScheduleTime) else {
                    return
                }
                
                times.append(newScheduleTime)
            }
        )
    }
    
    
    private func addNewTime() {
        var endlessLoopCounter = 0
        var newTimeAdded = times.last?.time.date?.addingTimeInterval(60) ?? Date.now
        
        // We assume that a user doesn't take a single medication more than the loop limit.
        while endlessLoopCounter < 100 {
            let newScheduleTime = ScheduleTime(time: Calendar.current.dateComponents([.hour, .minute], from: newTimeAdded))
            
            guard !times.contains(newScheduleTime) else {
                newTimeAdded.addTimeInterval(60)
                endlessLoopCounter += 1
                continue
            }
            
            times.append(newScheduleTime)
            return
        }
    }
}
