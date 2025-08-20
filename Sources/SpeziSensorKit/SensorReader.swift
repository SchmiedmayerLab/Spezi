//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

private import Foundation
public import Observation
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
@Observable
public final class SensorReader<Sample: AnyObject & Hashable>: SensorReaderProtocol, @unchecked Sendable {
    // We use a heap-allocated Array for building up the list of FetchResults;
    // for some reason this has significantly better performance when used as an associated value in an enum case
    // than simply using an Array directly.
    // (The issue was that, in the case of using the Array as the enum's associated value,
    // every time we'd get informed about a new fetch result by SensorKit, add it to the array and then re-assign the enum,
    // it'd end up making a copy of the array rather than just mutating it in place (even when using the `consume` operator)...)
    private final class FetchResultsArray {
        private(set) var fetchResults: [SensorKit.FetchResult<Sample>] = []
        func append(_ fetchResult: consuming SensorKit.FetchResult<Sample>) {
            fetchResults.append(fetchResult)
        }
    }
    
    private enum State {
        case idle
        case fetchingDevices(CheckedContinuation<[SRDevice], any Error>)
        case fetchingSamples(FetchResultsArray, CheckedContinuation<[SensorKit.FetchResult<Sample>], any Error>)
        case startingRecording(CheckedContinuation<Void, any Error>)
        case stoppingRecording(CheckedContinuation<Void, any Error>)
        
        var isIdle: Bool {
            switch self {
            case .idle: true
            default: false
            }
        }
    }
    
    @ObservationIgnored public let sensor: Sensor<Sample>
    @ObservationIgnored private var delegateImpl: SensorDelegate?
    @ObservationIgnored private let logger = Logger(subsystem: "edu.stanford.SpeziSensorKit", category: "SensorKit")
    @ObservationIgnored private let reader: SRSensorReader
    @ObservationIgnored @SensorKitActor private var state: State = .idle
    /// The lock that is used to ensure that no more than a single SensorKit fetch operation may occur at a time.
    @ObservationIgnored @SensorKitActor private let fetchOperationLock = Lock()
    @MainActor public private(set) var authorizationStatus: SRAuthorizationStatus = .notDetermined
    
    public nonisolated init(_ sensor: Sensor<Sample>) {
        self.sensor = sensor
        reader = SRSensorReader(sensor: sensor.srSensor)
        delegateImpl = SensorDelegate(reader: self)
        reader.delegate = delegateImpl
    }
    
    @SensorKitActor
    private func checkIsIdle() {
        precondition(state.isIdle)
    }
    
    /// Performs a locked SensorKit operation.
    ///
    /// This function ensures that at most a single operation may occur at a time.
    /// If another operation is already ongoing, this function will wait and resume only once the other operation has completed.
    @SensorKitActor
    private func lockedSensorKitOperation<Result, E>(
        _ operation: @SensorKitActor () async throws(E) -> sending Result
    ) async throws(E) -> sending Result {
        await fetchOperationLock.lock()
        checkIsIdle()
        defer {
            state = .idle
            fetchOperationLock.unlock()
        }
        return try await operation()
    }
    
    @SensorKitActor
    public func fetchDevices() async throws -> sending [SRDevice] {
        try await lockedSensorKitOperation {
            try await withCheckedThrowingContinuation { continuation in
                checkIsIdle()
                state = .fetchingDevices(continuation)
                reader.fetchDevices()
            }
        }
    }
    
    @SensorKitActor
    public func startRecording() async throws {
        try await lockedSensorKitOperation {
            try await withCheckedThrowingContinuation { continuation in
                checkIsIdle()
                state = .startingRecording(continuation)
                reader.startRecording()
            }
        }
    }
    
    @SensorKitActor
    public func stopRecording() async throws {
        try await lockedSensorKitOperation {
            try await withCheckedThrowingContinuation { continuation in
                checkIsIdle()
                state = .stoppingRecording(continuation)
                reader.stopRecording()
            }
        }
    }
    
    @SensorKitActor
    public func fetch(
        from device: SRDevice? = nil, // swiftlint:disable:this function_default_parameter_at_end
        timeRange: Range<Date>
    ) async throws -> [SensorKit.FetchResult<Sample>] {
        try await lockedSensorKitOperation {
            let fetchRequest = SRFetchRequest()
            if let device {
                fetchRequest.device = device
            }
            fetchRequest.from = .fromCFAbsoluteTime(_cf: timeRange.lowerBound.timeIntervalSinceReferenceDate)
            fetchRequest.to = .fromCFAbsoluteTime(_cf: timeRange.upperBound.timeIntervalSinceReferenceDate)
            return try await withCheckedThrowingContinuation { continuation in
                checkIsIdle()
                state = .fetchingSamples(FetchResultsArray(), continuation)
                reader.fetch(fetchRequest)
            }
        }
    }
}


extension SensorReader {
    // We put all of this into a separate, private type
    // so that the SensorReader class doesn't need to declare a public conformance to SRSensorReaderDelegate.
    private final class SensorDelegate: NSObject, SRSensorReaderDelegate, Sendable {
        unowned let reader: SensorReader
        
        init(reader: SensorReader) {
            self.reader = reader
        }
        
        func sensorReader(_ reader: SRSensorReader, didChange authorizationStatus: SRAuthorizationStatus) {
            Task { @MainActor in
                self.reader.authorizationStatus = authorizationStatus
            }
        }
        
        func sensorReader(_ reader: SRSensorReader, didFetch devices: [SRDevice]) {
            nonisolated(unsafe) let devices = devices
            Task { @SensorKitActor in
                switch self.reader.state {
                case .fetchingDevices(let continuation):
                    continuation.resume(returning: devices)
                default:
                    reportUnexpectedDelegateCallback()
                }
            }
        }
        
        func sensorReader(_ reader: SRSensorReader, fetchDevicesDidFailWithError error: any Error) {
            Task { @SensorKitActor in
                switch self.reader.state {
                case .fetchingDevices(let continuation):
                    continuation.resume(throwing: error)
                default:
                    reportUnexpectedDelegateCallback()
                }
            }
        }
        
        func sensorReader(_ reader: SRSensorReader, fetching fetchRequest: SRFetchRequest, didFetchResult result: SRFetchResult<AnyObject>) -> Bool {
            let fetchResult = SensorKit.FetchResult(result, for: self.reader.sensor)
            Task { @SensorKitActor in
                switch self.reader.state {
                case .fetchingSamples(let fetchResults, _):
                    fetchResults.append(fetchResult)
                default:
                    reportUnexpectedDelegateCallback()
                }
            }
            return true
        }
        
        func sensorReader(_ reader: SRSensorReader, fetching fetchRequest: SRFetchRequest, failedWithError error: any Error) {
            Task { @SensorKitActor in
                switch self.reader.state {
                case .fetchingSamples(_, let continuation):
                    continuation.resume(throwing: error)
                default:
                    reportUnexpectedDelegateCallback()
                }
            }
        }
        
        func sensorReader(_ reader: SRSensorReader, didCompleteFetch fetchRequest: SRFetchRequest) {
            Task { @SensorKitActor in
                switch self.reader.state {
                case let .fetchingSamples(fetchResults, continuation):
                    continuation.resume(returning: fetchResults.fetchResults)
                default:
                    reportUnexpectedDelegateCallback()
                }
            }
        }
        
        func sensorReaderWillStartRecording(_ reader: SRSensorReader) {
            Task { @SensorKitActor in
                switch self.reader.state {
                case .startingRecording(let continuation):
                    continuation.resume()
                default:
                    reportUnexpectedDelegateCallback()
                }
            }
        }
        
        func sensorReader(_ reader: SRSensorReader, startRecordingFailedWithError error: any Error) {
            Task { @SensorKitActor in
                switch self.reader.state {
                case .startingRecording(let continuation):
                    continuation.resume(throwing: error)
                default:
                    reportUnexpectedDelegateCallback()
                }
            }
        }
        
        func sensorReaderDidStopRecording(_ reader: SRSensorReader) {
            Task { @SensorKitActor in
                switch self.reader.state {
                case .stoppingRecording(let continuation):
                    continuation.resume()
                default:
                    reportUnexpectedDelegateCallback()
                }
            }
        }
        
        func sensorReader(_ reader: SRSensorReader, stopRecordingFailedWithError error: any Error) {
            Task { @SensorKitActor in
                switch self.reader.state {
                case .stoppingRecording(let continuation):
                    continuation.resume(throwing: error)
                default:
                    reportUnexpectedDelegateCallback()
                }
            }
        }
        
        @SensorKitActor
        private func reportUnexpectedDelegateCallback(_ caller: StaticString = #function) {
            guard self.reader.state.isIdle else {
                let stateDesc = "\(self.reader.state)"
                preconditionFailure("Received unexpected delegate callback '\(caller)' while in state \(stateDesc)")
            }
            self.reader.logger.error("Unexpectedly received delegate callback '\(caller)' while in idle state.")
        }
    }
}


// MARK: Utils

extension SensorReader {
    private final class Lock {
        private var isLocked = false
        private var waiters: [CheckedContinuation<Void, Never>] = []
        
        init() {}
        
        func lock() async {
            if !isLocked {
                precondition(waiters.isEmpty, "invalid state: lock is open but there are waiters.")
                isLocked = true
            } else {
                // the lock is locked.
                // we need to wait until it is our turn to obtain the lock.
                await withCheckedContinuation { continuation in
                    waiters.append(continuation)
                }
            }
        }
        
        func unlock() {
            precondition(isLocked, "invalid state: cannot unlock lock that isn't locked.")
            if waiters.isEmpty {
                // no one wants to take the lock over from us; we can simply open it
                isLocked = false
            } else {
                // if there are waiters, we keep the lock closed and (semantially) hand it over to the first continuation.
                waiters.removeFirst().resume()
            }
        }
    }
}
