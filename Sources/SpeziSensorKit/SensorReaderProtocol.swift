//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
public import SensorKit


/// A type-erased ``SensorReader``.
public protocol SensorReaderProtocol<Sample>: AnyObject, Sendable {
    associatedtype Sample: AnyObject, Hashable
    
    /// The reader's underlying ``Sensor``
    var sensor: Sensor<Sample> { get }
    
    /// Tells the OS to start data collection for this reader's sensor
    @SensorKitActor
    func startRecording() async throws
    
    /// Tells the OS to stop data collection for this reader's sensor
    @SensorKitActor
    func stopRecording() async throws
    
    /// Fetches a list of all devices that collect data for this sensor.
    @SensorKitActor
    func fetchDevices() async throws -> sending [SRDevice]
    
    /// Fetches data from SensorKit
    @SensorKitActor
    func fetch(from device: SRDevice?, timeRange: Range<Date>) async throws -> [SensorKit.FetchResult<Sample>]
}


extension SensorReaderProtocol {
    var typeErasedSensor: any AnySensor {
        sensor
    }
    
    /// Fetches data from SensorKit
    @SensorKitActor
    public func fetch(
        from device: SRDevice? = nil, // swiftlint:disable:this function_default_parameter_at_end
        mostRecentAvailable fetchDuration: Duration
    ) async throws -> [SensorKit.FetchResult<Sample>] {
        let endDate = Date.now.addingTimeInterval(-sensor.dataQuarantineDuration.timeInterval)
        let startDate = endDate.addingTimeInterval(-fetchDuration.timeInterval)
        return try await fetch(from: device, timeRange: startDate..<endDate)
    }
}
