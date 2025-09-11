//
// This source file is part of the My Heart Counts iOS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import Foundation
public import SensorKit


extension SRAmbientLightSample: SensorKitSampleProtocol {
    public struct SafeRepresentation: SensorKitSampleSafeRepresentation {
        public let timestamp: Date
        public let lux: Measurement<UnitIlluminance>
        public let placement: SRAmbientLightSample.SensorPlacement
        /// Chromaticity is only valid on supporting devices. If not supported, the values will be zero.
        public let chromacity: SRAmbientLightSample.Chromaticity
        
        init(timestamp: Date, sample: SRAmbientLightSample) {
            self.timestamp = timestamp
            self.lux = sample.lux
            self.placement = sample.placement
            self.chromacity = sample.chromaticity
        }
    }
    
    public static func processIntoSafeRepresentation(
        _ samples: some Sequence<(timestamp: Date, sample: SRAmbientLightSample)>
    ) -> [SafeRepresentation] {
        samples.map { .init(timestamp: $0, sample: $1) }
    }
}


extension SRAmbientLightSample.Chromaticity: @retroactive Equatable, @retroactive Hashable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
