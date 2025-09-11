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
/// The `Sensor` type models a sensor that can be used with SensorKit.
/// It is a thin wrapper around SensorKit's `SRSensor` type, adding sensor-specific information such as a user-displayable name for the sensor and its iOS-enforced data quarantine period.
///
/// Additionally, `Sensor`'s generic parameter is used to associate each sensor with its specific sample type used by SensorKit.
///
/// You use the ``SensorReader`` to fetch a sensor's data from SensorKit.
///
/// ## Topics
///
/// ### Instance Properties
/// - ``srSensor``
/// - ``displayName``
/// - ``dataQuarantineDuration``
///
/// ### Supported Sensors
/// - ``accelerometer``
/// - ``ambientLight``
/// - ``ambientPressure``
/// - ``deviceUsage``
/// - ``ecg``
/// - ``heartRate``
/// - ``onWrist``
/// - ``pedometer``
/// - ``ppg``
/// - ``visits``
/// - ``wristTemperature``
///
/// ### Supporting Types
/// - ``AnySensor``
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
