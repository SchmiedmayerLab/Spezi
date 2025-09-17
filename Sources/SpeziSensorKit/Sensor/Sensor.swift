//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import SensorKit
import SpeziFoundation


/// A Sensor that can be used with SensorKit.
///
/// ## Topics
///
/// ### Associated types
/// - ``Sample``
///
/// ### Initializers
/// - ``init(_:)``
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
/// ### Supported Sensors
/// - ``accelerometer``
/// - ``ambientLight``
/// - ``ambientPressure``
/// - ``deviceUsage``
/// - ``ecg``
/// - ``faceMetrics``
/// - ``heartRate``
/// - ``keyboardMetrics``
/// - ``mediaEvents``
/// - ``messagesUsage``
/// - ``odometer``
/// - ``onWrist``
/// - ``pedometer``
/// - ``phoneUsage``
/// - ``ppg``
/// - ``rotationRate``
/// - ``siriSpeechMetrics``
/// - ``telephonySpeechMetrics``
/// - ``visits``
/// - ``wristTemperature``
///
/// ### Other
/// - ``~=(_:_:)``
/// - ``==(_:_:)-(Sensor<Any>,AnySensor)``
/// - ``==(_:_:)-(AnySensor,Sensor<Any>)``
public struct Sensor<Sample: SensorKitSampleProtocol>: AnySensor {
    public typealias Sample = Sample
    
    @usableFromInline
    enum SensorKitFetchReturnType: Sendable {
        case object, array
    }
    
    public let srSensor: SRSensor
    public let displayName: String
    public let dataQuarantineDuration: Duration
    @usableFromInline let sensorKitFetchReturnType: SensorKitFetchReturnType
    
    @inlinable
    init(srSensor: SRSensor, displayName: String, dataQuarantineDuration: Duration, sensorKitFetchReturnType: SensorKitFetchReturnType) {
        self.srSensor = srSensor
        self.displayName = displayName
        self.dataQuarantineDuration = dataQuarantineDuration
        self.sensorKitFetchReturnType = sensorKitFetchReturnType
    }
    
    /// Creates a ``Sensor`` from a type-erased ``AnySensor``.
    ///
    /// Since ``Sensor`` is the only type allowed to conform to ``AnySensor``, this is guaranteed to always succeed.
    @inlinable
    public init(_ typeErased: any AnySensor<Sample>) {
        // SAFETY: `Sensor` is the only type allowed to conform to `AnySensor`.
        self = typeErased as! Self // swiftlint:disable:this force_cast
    }
}
