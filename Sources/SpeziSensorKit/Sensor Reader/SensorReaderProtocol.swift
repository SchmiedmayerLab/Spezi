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
public protocol SensorReaderProtocol<Sample>: Sendable {
    associatedtype Sample: SensorKitSampleProtocol
    
    /// The reader's underlying ``Sensor``
    var sensor: Sensor<Sample> { get }
    
    /// The sensor's current authorization status.
    var authorizationStatus: SRAuthorizationStatus { get }
    
    /// Tells the OS to start data collection for this reader's sensor
    func startRecording() async throws
    
    /// Tells the OS to stop data collection for this reader's sensor
    func stopRecording() async throws
    
    /// Fetches a list of all devices that collect data for this sensor.
    func fetchDevices() async throws -> sending [SRDevice]
    
    /// Fetches data from SensorKit
    func fetch(from device: SRDevice, timeRange: Range<Date>) async throws -> [Sample.SafeRepresentation]
}


extension SensorReaderProtocol {
    var typeErasedSensor: any AnySensor {
        sensor
    }
    
    /// Fetches data from SensorKit
    public func fetch(from device: SRDevice, mostRecentAvailable fetchDuration: Duration) async throws -> [Sample.SafeRepresentation] {
        let endDate = sensor.currentQuarantineBegin
        let startDate = endDate.addingTimeInterval(-fetchDuration.timeInterval)
        return try await fetch(from: device, timeRange: startDate..<endDate)
    }
    
    /// Performs a batched fetch, using a managed query anchor.
    @available(iOS 18, *)
    func fetchBatched(anchor: ManagedQueryAnchor) async throws -> some AsyncSequence<[Sample.SafeRepresentation], any Error> {
        try await AnchoredAsyncDataFetcher(reader: self, anchor: anchor)
    }
}
