//
// This source file is part of the My Heart Counts iOS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import CoreMotion
public import Foundation
public import SensorKit


// MARK: DefaultSensorKitSampleSafeRepresentation

/// A default ``SensorKitSampleSafeRepresentation``, intended for sensors whose types are already `Sendable` and not confined to the SensorKit thread.
@dynamicMemberLookup
public struct DefaultSensorKitSampleSafeRepresentation<Sample: Hashable & Sendable>: SensorKitSampleSafeRepresentation {
    public let timestamp: Date
    /// The underlying sample.
    public let sample: Sample
    
    @inlinable
    init(timestamp: Date, sample: Sample) {
        self.timestamp = timestamp
        self.sample = sample
    }
    
    /// Access a property on the underlying sample.
    @inlinable
    public subscript<T>(dynamicMember keyPath: KeyPath<Sample, T>) -> T {
        sample[keyPath: keyPath]
    }
}


// MARK: SampleType Extensions

extension SRWristTemperatureSession: SensorKitSampleProtocol {
    public typealias SafeRepresentation = DefaultSensorKitSampleSafeRepresentation<SRWristTemperatureSession>
}


@available(iOS 17.4, *)
extension SRPhotoplethysmogramSample: SensorKitSampleProtocol {
    public typealias SafeRepresentation = DefaultSensorKitSampleSafeRepresentation<SRPhotoplethysmogramSample>
}


extension SRSpeechMetrics: SensorKitSampleProtocol {
    public typealias SafeRepresentation = DefaultSensorKitSampleSafeRepresentation<SRSpeechMetrics>
}


extension SRMediaEvent: SensorKitSampleProtocol {
    public typealias SafeRepresentation = DefaultSensorKitSampleSafeRepresentation<SRMediaEvent>
}


extension SRFaceMetrics: SensorKitSampleProtocol {
    public typealias SafeRepresentation = DefaultSensorKitSampleSafeRepresentation<SRFaceMetrics>
}


extension CMOdometerData: SensorKitSampleProtocol {
    public typealias SafeRepresentation = DefaultSensorKitSampleSafeRepresentation<CMOdometerData>
}
