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
        /// A value that uniquely identifies this measurement.
        public let identifier: UInt64
        /// The ambient pressure, in kPa (kilopascals).
        public let pressure: Measurement<UnitPressure>
        /// The ambient temperature, in C (degrees centrigrade).
        public let temperature: Measurement<UnitTemperature>
        
        @inlinable
        init(_ data: CMRecordedPressureData) {
            timestamp = data.startDate
            identifier = data.identifier
            pressure = data.pressure
            temperature = data.temperature
        }
    }
    
    @inlinable
    public static func processIntoSafeRepresentation(
        _ samples: some Sequence<(timestamp: Date, sample: CMRecordedPressureData)>
    ) -> [SafeRepresentation] {
        samples.map { .init($1) }
    }
}
