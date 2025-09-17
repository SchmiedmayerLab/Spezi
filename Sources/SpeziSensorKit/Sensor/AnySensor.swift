//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import SensorKit
import SpeziFoundation


/// A type-erased ``Sensor``
///
/// - Important: ``Sensor`` is the only type allowed to conform to ``AnySensor``.
///
/// ## Topics
///
/// ### Associated types
/// - ``Sample``
///
/// ### Instance Properties
/// - ``srSensor``
/// - ``id``
/// - ``displayName``
/// - ``authorizationStatus``
/// - ``dataQuarantineDuration``
/// - ``suggestedBatchSize``
///
/// ### Instance Methods
/// - ``startRecording()``
/// - ``stopRecording()``
/// - ``fetchDevices()``
/// - ``fetch(from:timeRange:)``
/// - ``fetch(from:mostRecentAvailable:)``
///
/// ### Other
/// - ``~=(_:_:)``
/// - ``==(_:_:)-(Sensor<Any>,AnySensor)``
/// - ``==(_:_:)-(AnySensor,Sensor<Any>)``
public protocol AnySensor<Sample>: Hashable, Identifiable, Sendable {
    /// The type of the sensor's resulting samples.
    associatedtype Sample: SensorKitSampleProtocol
    
    /// The underlying SensorKit `SRSensor`.
    var srSensor: SRSensor { get }
    /// The recommended display name.
    var displayName: String { get }
    /// How long the system hold data in quarantine before it can be queried by applications.
    var dataQuarantineDuration: Duration { get }
    /// The sensor's unique identifier.
    var id: String { get }
}


extension AnySensor {
    @inlinable public var id: String { // swiftlint:disable:this missing_docs
        srSensor.rawValue
    }
    
    var currentQuarantineBegin: Date {
        .now.addingTimeInterval(-dataQuarantineDuration.timeInterval)
    }
    
    /// The recommended batch size for fetching data from this sensor.
    public var suggestedBatchSize: Duration {
        switch self {
        case Sensor.onWrist, Sensor.visits:
            .days(1)
        default:
            if #available(iOS 17.4, *), self == Sensor.ecg {
                .days(1)
            } else {
                .hours(2)
            }
        }
    }
}

// MARK: Other

/// Compare two sensors, based on their identifiers
@inlinable
public func ~= (lhs: Sensor<some Any>, rhs: any AnySensor) -> Bool { // swiftlint:disable:this static_operator
    lhs.id == rhs.id
}

/// Compare two sensors, based on their identifiers
@inlinable
public func == (lhs: Sensor<some Any>, rhs: any AnySensor) -> Bool { // swiftlint:disable:this static_operator
    lhs.id == rhs.id
}

/// Compare two sensors, based on their identifiers
@inlinable
public func == (lhs: any AnySensor, rhs: Sensor<some Any>) -> Bool { // swiftlint:disable:this static_operator
    lhs.id == rhs.id
}
