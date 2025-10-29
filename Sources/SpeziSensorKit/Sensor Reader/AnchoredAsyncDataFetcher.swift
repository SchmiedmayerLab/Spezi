//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SensorKit


/// An `AsyncSequence` and `AsyncIterator` that can be used to fetch and process data from SensorKit, split into distinct batches.
///
/// Each batch will be fetched from SensorKit on demand, i.e. when ``next(isolation:)`` is called.
///
/// - Important: Due to the lazy nature of this type, and the fact that it uses a query anchor internally to keep track of already-fetched time ranges, the sequence should only be iterated once.
@available(iOS 18, *)
struct AnchoredAsyncDataFetcher<Sample: SensorKitSampleProtocol>: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = (SensorKit.BatchInfo, [Sample.SafeRepresentation])
    typealias Failure = any Error
    typealias AsyncIterator = Self
    
    private enum State {
        case initial
        case process(timeRange: Range<Date>, devices: [SRDevice])
        /// The data fetcher is done, i.e. has fetched (and returned) all data that is currently available.
        case done
    }
    
    private let sensor: Sensor<Sample>
    private let anchor: ManagedQueryAnchor
    private let quarantineCutoff: Date
    nonisolated(unsafe) private let devices: [SRDevice]
    
    private var state: State = .initial
    
    init(sensor: some AnySensor<Sample>, anchor: ManagedQueryAnchor) async throws {
        self.sensor = Sensor(sensor)
        self.anchor = anchor
        self.quarantineCutoff = sensor.currentQuarantineBegin
        self.devices = try await sensor.fetchDevices()
    }
    
    consuming func makeAsyncIterator() -> Self {
        self
    }
    
    private mutating func advanceState() throws {
        switch state {
        case .done:
            return
        case .initial:
            var currentAnchor = try anchor.value
            guard currentAnchor.timestamp < quarantineCutoff else {
                state = .done
                return
            }
            if currentAnchor.timestamp == .distantPast {
                // first time
                currentAnchor = .init(timestamp: quarantineCutoff.addingTimeInterval(-Duration.days(7).timeInterval))
                try anchor.update(currentAnchor)
            }
            let batchStartDate = currentAnchor.timestamp
            let batchEndDate = Swift.min(batchStartDate.addingTimeInterval(sensor.suggestedBatchSize.timeInterval), quarantineCutoff)
            state = .process(timeRange: batchStartDate..<batchEndDate, devices: devices)
        case let .process(timeRange, devices):
            guard devices.count <= 1 else {
                state = .process(timeRange: timeRange, devices: Array(devices.dropFirst()))
                return
            }
            try self.anchor.update(.init(timestamp: timeRange.upperBound))
            guard timeRange.upperBound < quarantineCutoff else {
                // we already were processing the last (currently available) batch
                state = .done
                return
            }
            let newStartDate = timeRange.upperBound
            let newEndDate = Swift.min(newStartDate.addingTimeInterval(sensor.suggestedBatchSize.timeInterval), quarantineCutoff)
            state = .process(timeRange: newStartDate..<newEndDate, devices: self.devices)
        }
    }
    
    mutating func next(isolation: isolated (any Actor)?) async throws(Failure) -> Element? {
        switch state {
        case .done:
            return nil
        case .initial:
            try advanceState()
            return try await next(isolation: isolation)
        case let .process(timeRange, devices):
            guard let _device = devices.first else { // swiftlint:disable:this identifier_name
                try advanceState()
                return try await next(isolation: isolation)
            }
            nonisolated(unsafe) let device = _device
            let results = try await sensor.fetch(from: device, timeRange: timeRange)
            try advanceState()
            let batchInfo = SensorKit.BatchInfo(timeRange: timeRange, device: SensorKit.DeviceInfo(device))
            return (batchInfo, results)
        }
    }
}


extension SensorKit {
    public final class DeviceInfo: CustomStringConvertible, Sendable {
        /// The user-defined name of the device.
        public let model: String
        /// The framework-defined name of the device.
        public let name: String
        /// The device’s operating system.
        public let systemName: String
        /// The device’s operating system version.
        public let systemVersion: String
        /// A string that identifies the device used to save a sample.
        public let productType: String
        
        public var description: String {
            "model=\(model); name=\(name); systemName=\(systemName); systemVersion=\(systemVersion); productType=\(productType)"
        }
        
        public init(_ device: SRDevice) {
            model = device.model
            name = device.name
            systemName = device.systemName
            systemVersion = device.systemVersion
            productType = device.productType
        }
    }
}


extension SensorKit {
    public struct BatchInfo: Sendable {
        /// The time range queried for when SensorKit returned this batch's samples.
        public let timeRange: Range<Date>
        /// The source device queried for when SensorKit returned this batch's samples.
        public let device: DeviceInfo
        
        public init(timeRange: Range<Date>, device: DeviceInfo) {
            self.timeRange = timeRange
            self.device = device
        }
    }
}
