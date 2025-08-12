//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import CoreMotion
@preconcurrency public import SensorKit
public import SpeziFoundation


/// A type-erased ``Sensor``
public protocol AnySensor: Hashable, Sendable {
    /// The underlying SensorKit `SRSensor`
    var srSensor: SRSensor { get }
    /// The recommended display name
    var displayName: String { get }
    /// How long the system hold data in quarantine before it can be queried by applications.
    var dataQuarantineDuration: Duration { get }
}


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
public struct Sensor<Sample: AnyObject & Hashable>: AnySensor {
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
}

extension Sensor where Sample == SRWristDetection {
    /// A sensor that describes the watch’s position on the wrist.
    @inlinable public static var onWrist: Sensor<SRWristDetection> {
        Sensor(
            srSensor: .onWristState,
            displayName: "On-Wrist State",
            dataQuarantineDuration: .hours(24),
            sensorKitFetchReturnType: .object
        )
    }
}

extension Sensor where Sample == SRAmbientLightSample {
    /// A sensor that provides ambient light information.
    @inlinable public static var ambientLight: Sensor<SRAmbientLightSample> {
        Sensor(
            srSensor: .ambientLightSensor,
            displayName: "Ambient Light",
            dataQuarantineDuration: .hours(24),
            sensorKitFetchReturnType: .object
        )
    }
}

extension Sensor where Sample == CMRecordedPressureData {
    /// A sensor that provides pressure and temperature metrics.
    @inlinable public static var ambientPressure: Sensor<CMRecordedPressureData> {
        Sensor(
            srSensor: .ambientPressure,
            displayName: "Ambient Pressure",
            dataQuarantineDuration: .hours(24),
            sensorKitFetchReturnType: .array
        )
    }
}

extension Sensor where Sample == CMHighFrequencyHeartRateData {
    /// A sensor that provides the user’s heart rate data.
    @inlinable public static var heartRate: Sensor<CMHighFrequencyHeartRateData> {
        Sensor(
            srSensor: .heartRate,
            displayName: "Heart Rate",
            dataQuarantineDuration: .hours(24),
            sensorKitFetchReturnType: .object
        )
    }
}

extension Sensor where Sample == CMPedometerData {
    /// A sensor that provides information about the user’s steps.
    @inlinable public static var pedometer: Sensor<CMPedometerData> {
        Sensor(
            srSensor: .pedometerData,
            displayName: "Pedometer",
            dataQuarantineDuration: .hours(24),
            sensorKitFetchReturnType: .object
        )
    }
}

extension Sensor where Sample == SRWristTemperatureSession {
    /// A sensor that provides wrist temperature while the user sleeps.
    @inlinable public static var wristTemperature: Sensor<SRWristTemperatureSession> {
        Sensor(
            srSensor: .wristTemperature,
            displayName: "Wrist Temperature",
            dataQuarantineDuration: .hours(24),
            sensorKitFetchReturnType: .object
        )
    }
}

@available(iOS 17.4, *)
extension Sensor where Sample == SRPhotoplethysmogramSample {
    /// A sensor that streams sample PPG sensor data.
    @inlinable public static var ppg: Sensor<SRPhotoplethysmogramSample> {
        Sensor(
            srSensor: .photoplethysmogram,
            displayName: "PPG",
            dataQuarantineDuration: .hours(24),
            sensorKitFetchReturnType: .array
        )
    }
}

@available(iOS 17.4, *)
extension Sensor where Sample == SRElectrocardiogramSample {
    /// A sensor that streams sample ECG sensor data.
    @inlinable public static var ecg: Sensor<SRElectrocardiogramSample> {
        Sensor(
            srSensor: .electrocardiogram,
            displayName: "ECG",
            dataQuarantineDuration: .hours(24),
            sensorKitFetchReturnType: .array
        )
    }
}

extension Sensor where Sample == SRVisit {
    /// A sensor that provides information about frequently visited locations.
    @inlinable public static var visits: Sensor<SRVisit> {
        Sensor(
            srSensor: .visits,
            displayName: "Visits",
            dataQuarantineDuration: .hours(24),
            sensorKitFetchReturnType: .object
        )
    }
}

extension Sensor where Sample == SRDeviceUsageReport {
    /// A sensor that provides information about device usage.
    @inlinable public static var deviceUsage: Sensor<SRDeviceUsageReport> {
        Sensor(
            srSensor: .deviceUsageReport,
            displayName: "Device Usage Report",
            dataQuarantineDuration: .hours(24),
            sensorKitFetchReturnType: .object
        )
    }
}
