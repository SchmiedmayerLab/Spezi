//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

private import Foundation
private import OSLog
public import SensorKit
private import SpeziFoundation


/// Read samples from a SensorKit ``Sensor``.
///
/// ## Topics
///
/// ### Initializers
/// - ``init(_:)``
///
/// ### Instance Properties
/// - ``sensor``
/// - ``authorizationStatus``
///
/// ### Operations
/// - ``fetchDevices()``
/// - ``fetch(from:timeRange:)``
/// - ``fetch(from:mostRecentAvailable:)``
///
/// ### Supporting Types
/// - ``SensorReaderProtocol``
public struct SensorReader<Sample: SensorKitSampleProtocol>: SensorReaderProtocol, Sendable {
    public let sensor: Sensor<Sample>
    private let logger = Logger(subsystem: "edu.stanford.SpeziSensorKit", category: "SensorKit")
    
    public var authorizationStatus: SRAuthorizationStatus {
        SRSensorReader(sensor: sensor.srSensor).authorizationStatus
    }
    
    /// Creates a new Sensor Reader.
    public init(_ sensor: Sensor<Sample>) {
        self.sensor = sensor
    }
    
    
    public func fetchDevices() async throws -> sending [SRDevice] {
        let reader = SRSensorReader(sensor: sensor.srSensor)
        let delegate = DevicesFetcherDelegate()
        reader.delegate = delegate
        return try await withCheckedThrowingContinuation { continuation in
            delegate.continuation = continuation
            reader.fetchDevices()
        }
    }
    
    public func startRecording() async throws {
        let reader = SRSensorReader(sensor: sensor.srSensor)
        let delegate = StartStopRecordingDelegate()
        reader.delegate = delegate
        try await withCheckedThrowingContinuation { continuation in
            delegate.continuation = continuation
            reader.startRecording()
        }
    }
    
    
    public func stopRecording() async throws {
        let reader = SRSensorReader(sensor: sensor.srSensor)
        let delegate = StartStopRecordingDelegate()
        reader.delegate = delegate
        try await withCheckedThrowingContinuation { continuation in
            delegate.continuation = continuation
            reader.stopRecording()
        }
    }
    
    public func fetch(from device: SRDevice, timeRange: Range<Date>) async throws -> [Sample.SafeRepresentation] {
        let reader = SRSensorReader(sensor: sensor.srSensor)
        let delegate = SamplesFetcherDelegate(sensor: sensor)
        return try await withCheckedThrowingContinuation { continuation in
            delegate.continuation = continuation
            reader.delegate = delegate
            let fetchRequest = SRFetchRequest()
            fetchRequest.device = device
            fetchRequest.from = .fromCFAbsoluteTime(_cf: timeRange.lowerBound.timeIntervalSinceReferenceDate)
            fetchRequest.to = .fromCFAbsoluteTime(_cf: timeRange.upperBound.timeIntervalSinceReferenceDate)
            reader.fetch(fetchRequest)
        }
    }
}

extension SensorReader {
    private final class StartStopRecordingDelegate: NSObject, SRSensorReaderDelegate {
        var continuation: CheckedContinuation<Void, any Error>?
        
        func sensorReaderWillStartRecording(_ reader: SRSensorReader) {
            continuation?.resume()
            continuation = nil
        }
        
        func sensorReaderDidStopRecording(_ reader: SRSensorReader) {
            continuation?.resume()
            continuation = nil
        }
        
        func sensorReader(_ reader: SRSensorReader, startRecordingFailedWithError error: any Error) {
            continuation?.resume(throwing: error)
            continuation = nil
        }
        
        func sensorReader(_ reader: SRSensorReader, stopRecordingFailedWithError error: any Error) {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
    
    
    private final class DevicesFetcherDelegate: NSObject, SRSensorReaderDelegate {
        var continuation: CheckedContinuation<[SRDevice], any Error>?
        
        func sensorReader(_ reader: SRSensorReader, didFetch devices: [SRDevice]) {
            nonisolated(unsafe) let devices = devices
            continuation?.resume(returning: devices)
            continuation = nil
        }
        
        func sensorReader(_ reader: SRSensorReader, fetchDevicesDidFailWithError error: any Error) {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
    
    
    private final class SamplesFetcherDelegate: NSObject, SRSensorReaderDelegate {
        private let sensor: Sensor<Sample>
        var continuation: CheckedContinuation<[Sample.SafeRepresentation], any Error>?
        private var results: [SensorKit.FetchResult<Sample>] = []
        
        init(sensor: Sensor<Sample>) {
            self.sensor = sensor
        }
        
        func sensorReader(_ reader: SRSensorReader, fetching fetchRequest: SRFetchRequest, didFetchResult result: SRFetchResult<AnyObject>) -> Bool {
            // The docs say that "If the caller needs to access the result at a later time, it must be copied not merely retained".
            guard let result = result.copy() as? SRFetchResult<AnyObject> else {
                // should be unreachable
                return true
            }
            let fetchResult = SensorKit.FetchResult(result, for: self.sensor)
            self.results.append(fetchResult)
            return true
        }
        
        func sensorReader(_ reader: SRSensorReader, fetching fetchRequest: SRFetchRequest, failedWithError error: any Error) {
            continuation?.resume(throwing: error)
            results = []
            continuation = nil
        }
        
        func sensorReader(_ reader: SRSensorReader, didCompleteFetch fetchRequest: SRFetchRequest) {
            guard let continuation else {
                self.results = []
                return
            }
            nonisolated(unsafe) let results = results
            let samples = SensorKit.FetchResultsIterator(results).lazy.map {
                (timestamp: $0, sample: unsafeDowncast($1, to: Sample.SafeRepresentationProcessingInput.self))
            }
            do {
                let processedResults: [Sample.SafeRepresentation] = try Sample.processIntoSafeRepresentation(samples)
                continuation.resume(returning: processedResults)
            } catch {
                continuation.resume(throwing: error)
            }
            self.results = []
            self.continuation = nil
        }
    }
}
