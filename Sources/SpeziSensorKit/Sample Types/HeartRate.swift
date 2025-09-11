//
// This source file is part of the My Heart Counts iOS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import CoreMotion
public import Foundation


extension CMHighFrequencyHeartRateData: SensorKitSampleProtocol {
    public struct SafeRepresentation: SensorKitSampleSafeRepresentation {
        public let timestamp: Date
        public let value: Double
        public let confidence: CMHighFrequencyHeartRateDataConfidence
        
        fileprivate init(timestamp: Date, sample: CMHighFrequencyHeartRateData) {
            self.timestamp = sample.date ?? timestamp
            self.value = sample.heartRate
            self.confidence = sample.confidence
        }
    }
    
    public static func processIntoSafeRepresentation(
        _ samples: some Sequence<(timestamp: Date, sample: CMHighFrequencyHeartRateData)>
    ) -> [SafeRepresentation] {
        samples.map { .init(timestamp: $0, sample: $1) }
    }
}
