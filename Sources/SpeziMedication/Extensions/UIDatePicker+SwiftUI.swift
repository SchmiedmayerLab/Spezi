//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct ScheduledTimeDatePicker: UIViewRepresentable {
    @MainActor
    class Coordinator: NSObject {
        private var lastDate: Date
        private let date: Binding<Date>
        fileprivate var excludedDates: [Date]
        
        
        fileprivate init(date: Binding<Date>, excludedDates: [Date]) {
            self.date = date
            self.lastDate = date.wrappedValue
            self.excludedDates = excludedDates
        }
        
        
        @objc
        fileprivate func valueChanged(datePicker: UIDatePicker, forEvent event: UIEvent) {
            guard !excludedDates.contains(datePicker.date) else {
                datePicker.date = lastDate
                return
            }
            
            lastDate = datePicker.date
        }
        
        @objc
        fileprivate func editingDidEnd(datePicker: UIDatePicker, forEvent event: UIEvent) {
            self.date.wrappedValue = datePicker.date
        }
    }
    
    
    static let minuteInterval = 5
    
    
    @Binding private var date: Date
    private let excludedDates: [Date]
    
    
    init(date: Binding<Date>, excludedDates: [Date]) {
        self._date = date
        self.excludedDates = excludedDates
    }
    
    
    func makeCoordinator() -> Self.Coordinator {
        Coordinator(date: $date, excludedDates: excludedDates)
    }
    
    func makeUIView(context: Context) -> UIDatePicker {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .compact
        datePicker.minuteInterval = Self.minuteInterval
        datePicker.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged), for: .valueChanged)
        datePicker.addTarget(context.coordinator, action: #selector(Coordinator.editingDidEnd), for: .editingDidEnd)
        return datePicker
    }
    
    func updateUIView(_ datePicker: UIDatePicker, context: Context) {
        datePicker.date = date
        context.coordinator.excludedDates = excludedDates.filter { $0 != date }
    }
}
