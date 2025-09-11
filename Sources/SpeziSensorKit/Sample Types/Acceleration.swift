//
// This source file is part of the My Heart Counts iOS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import CoreMotion


extension CMRecordedAccelerometerData: SensorKitSampleProtocol {
    public struct SafeRepresentation: SensorKitSampleSafeRepresentation {
        public let timestamp: Date
        public let identifier: UInt64
        public let acceleration: CMAcceleration
        
        init(_ data: CMRecordedAccelerometerData) {
            timestamp = data.startDate
            identifier = data.identifier
            acceleration = data.acceleration
        }
    }
    
    public static func processIntoSafeRepresentation(
        _ samples: some Sequence<(timestamp: Date, sample: CMRecordedAccelerometerData)>
    ) -> [SafeRepresentation] {
        samples.map { .init($0.sample) }
    }
}


extension CMAcceleration: @retroactive Equatable, @retroactive Hashable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
    
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(z)
    }
}
