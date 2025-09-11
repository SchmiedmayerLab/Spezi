//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

public import SensorKit
import SpeziFoundation


/// A `Sendable` representation of a data sample obtained from SensorKit.
public protocol SensorKitSampleSafeRepresentation: Hashable, Sendable {
    /// The sample's timestamp.
    ///
    /// Depending on the specific sensor this sample originates from, the timestamp represents either the actual time the sample was recorded, or the time it was added to SensorKit.
    var timestamp: Date { get }
}


/// A type that is returned from a SensorKit query.
///
/// - Important: For any type that declares conformance to  ``SensorKitSampleProtocol``, the ``SafeRepresentationProcessingInput`` type **must** be equal to the type itself.
///     Failure to do so is a programmer error and will result in the program crashing at runtime.
///     This associatedtype is required to work around type system limitations.
public protocol SensorKitSampleProtocol: AnyObject, Hashable {
    /// A "safe" `Sendable` representation of the type.
    ///
    /// This is required because most SensorKit types are not Sendable and can only be used on the specific DispatchQueue used internally by SensorKit.
    associatedtype SafeRepresentation: SensorKitSampleSafeRepresentation
    
    /// The sample input when processing samples of this type into their safe representation.
    associatedtype SafeRepresentationProcessingInput: AnyObject, Hashable = Self
    
    /// Processes a batch of samples into their safe representation.
    @inlinable
    static func processIntoSafeRepresentation(
        _ samples: some Sequence<(timestamp: Date, sample: SafeRepresentationProcessingInput)>
    ) throws -> [SafeRepresentation]
}


extension SensorKitSampleProtocol where SafeRepresentation == SafeRepresentationProcessingInput {
    @inlinable
    public static func processIntoSafeRepresentation( // swiftlint:disable:this missing_docs
        _ samples: some Sequence<(timestamp: Date, sample: SafeRepresentationProcessingInput)>
    ) -> [SafeRepresentation] {
        samples.map(\.sample)
    }
}

extension SensorKitSampleProtocol where SafeRepresentation == DefaultSensorKitSampleSafeRepresentation<SafeRepresentationProcessingInput> {
    @inlinable
    public static func processIntoSafeRepresentation( // swiftlint:disable:this missing_docs
        _ samples: some Sequence<(timestamp: Date, sample: SafeRepresentationProcessingInput)>
    ) -> [SafeRepresentation] {
        samples.map { .init(timestamp: $0, sample: $1) }
    }
}


/// A type-erased ``Sensor``
///
/// - Important: The ``AnySensor`` protocol is public, but your application should not declare any new conformances to it; ``Sensor`` is the only type allowed to conform to ``AnySensor``.
public protocol AnySensor<Sample>: Hashable, Identifiable, Sendable {
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
