//
// This source file is part of the My Heart Counts iOS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import CoreMotion
public import Foundation


extension CMRecordedPressureData: SensorKitSampleProtocol {
    public struct SafeRepresentation: SensorKitSampleSafeRepresentation {
        public var timestamp: Date
        public let identifier: UInt64
        public let pressure: Measurement<UnitPressure>
        public let temperature: Measurement<UnitTemperature>
        
        init(_ data: CMRecordedPressureData) {
            timestamp = data.startDate
            identifier = data.identifier
            pressure = data.pressure
            temperature = data.temperature
        }
    }
    
    public static func processIntoSafeRepresentation(
        _ samples: some Sequence<(timestamp: Date, sample: CMRecordedPressureData)>
    ) -> [SafeRepresentation] {
        samples.map { .init($1) }
    }
}
