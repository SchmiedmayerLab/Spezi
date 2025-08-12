//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import Foundation
import SensorKit
import SpeziFoundation


extension SensorKit {
    /// A batch of samples returned by SensorKit
    public struct FetchResult<Sample: AnyObject & Hashable>: Hashable, @unchecked Sendable {
        /// The SensorKit framework's timestamp associated with this batch of samples
        public let sensorKitTimestamp: Date
        /// The samples.
        public let samples: [Sample]
        
        init(_ fetchResult: SRFetchResult<AnyObject>, for sensor: Sensor<Sample>) {
            sensorKitTimestamp = Date(timeIntervalSinceReferenceDate: fetchResult.timestamp.toCFAbsoluteTime())
            samples = switch sensor.sensorKitFetchReturnType {
            case .object:
                [unsafeDowncast(fetchResult.sample, to: Sample.self)]
            case .array:
                Array(_immutableCocoaArray: unsafeDowncast(fetchResult.sample, to: NSArray.self))
            }
        }
    }
}


extension SensorKit.FetchResult: RandomAccessCollection {
    public var startIndex: Int {
        samples.startIndex
    }
    
    public var endIndex: Int {
        samples.endIndex
    }
    
    public subscript(position: Int) -> Sample {
        samples[position]
    }
}
