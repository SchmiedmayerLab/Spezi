//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct EditScheduleTimeRow: View {
    @Binding private var time: ScheduledTime
    @Binding private var times: [ScheduledTime]
    
    @FocusState private var dosageFieldIsFocused: Bool
    
    
    private let numberOfDosageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    
    var body: some View {
        HStack {
            Button(
                action: {
                    times.removeAll(where: { $0.id == time.id })
                },
                label: {
                    Image(systemName: "minus.circle.fill")
                        .accessibilityLabel(Text("Delete", bundle: .module))
                        .foregroundStyle(Color.red)
                }
            )
                .buttonStyle(.borderless)
            ScheduledTimeDatePicker(
                date: $time.date.animation(),
                excludedDates: times.map(\.date)
            )
                .frame(width: 100)
            Spacer()
            TextField(
                String(localized: "Quantity", bundle: .module),
                value: $time.dosage,
                formatter: numberOfDosageFormatter
            )
                .focused($dosageFieldIsFocused)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .frame(maxWidth: 90)
        }
            .background {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dosageFieldIsFocused = false
                    }
                    .padding(-32)
            }
            .onChange(of: time.date) {
                withAnimation {
                    times.sort()
                }
            }
    }
    
    
    init(time: Binding<ScheduledTime>, times: Binding<[ScheduledTime]>) {
        self._time = time
        self._times = times
    }
}
