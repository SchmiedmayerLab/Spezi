//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziHealthKit


/// Defines a set of HealthKit sample types that should be collected as part of a study.
public struct HealthSampleTypesCollection: StudyDefinitionElement {
    private enum CodingKeys: CodingKey {
        case quantityTypes
        case correlationTypes
        case categoryTypes
    }
    
    private enum CodingError: Error {
        case unableToFindSampleType((any _HKSampleWithSampleType).Type, identifier: String)
    }
    
    /// The set of quantity types to collect.
    public let quantityTypes: Set<SampleType<HKQuantitySample>>
    /// The set of correlation types to collect.
    public let correlationTypes: Set<SampleType<HKCorrelation>>
    /// The set of category types to collect.
    public let categoryTypes: Set<SampleType<HKCategorySample>>
    
    /// Creates a new `HealthSampleTypesCollection`, using the specified sample types.
    public init(
        quantityTypes: Set<SampleType<HKQuantitySample>> = [],
        correlationTypes: Set<SampleType<HKCorrelation>> = [],
        categoryTypes: Set<SampleType<HKCategorySample>> = []
    ) {
        self.quantityTypes = quantityTypes
        self.correlationTypes = correlationTypes
        self.categoryTypes = categoryTypes
    }
    
    public init(from decoder: any Decoder) throws {
        func mapRawValuesIntoSampleTypes<T>(
            makeSampleType: (String) -> SampleType<T>?,
            rawIdentifiers: Set<String>
        ) throws -> Set<SampleType<T>> {
            var sampleTypes: Set<SampleType<T>> = []
            for identifier in rawIdentifiers {
                if let sampleType = makeSampleType(identifier) {
                    sampleTypes.insert(sampleType)
                } else {
                    throw CodingError.unableToFindSampleType(
                        // SAFETY: we know that the type will always conform to the protocol
                        T.self as! (any _HKSampleWithSampleType).Type, // swiftlint:disable:this force_cast
                        identifier: identifier
                    )
                }
            }
            return sampleTypes
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        quantityTypes = try mapRawValuesIntoSampleTypes(
            makeSampleType: { SampleType<HKQuantitySample>(HKQuantityTypeIdentifier(rawValue: $0)) },
            rawIdentifiers: try container.decode(Set<String>.self, forKey: .quantityTypes)
        )
        correlationTypes = try mapRawValuesIntoSampleTypes(
            makeSampleType: { SampleType<HKCorrelation>(HKCorrelationTypeIdentifier(rawValue: $0)) },
            rawIdentifiers: try container.decode(Set<String>.self, forKey: .correlationTypes)
        )
        categoryTypes = try mapRawValuesIntoSampleTypes(
            makeSampleType: { SampleType<HKCategorySample>(HKCategoryTypeIdentifier(rawValue: $0)) },
            rawIdentifiers: try container.decode(Set<String>.self, forKey: .categoryTypes)
        )
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(quantityTypes.map(\.identifier.rawValue), forKey: .quantityTypes)
        try container.encode(correlationTypes.map(\.identifier.rawValue), forKey: .correlationTypes)
        try container.encode(categoryTypes.map(\.identifier.rawValue), forKey: .categoryTypes)
    }
}


extension HealthSampleTypesCollection {
    /// `true` iff the object is completely empty
    public var isEmpty: Bool {
        quantityTypes.isEmpty && correlationTypes.isEmpty && categoryTypes.isEmpty
    }
    
    /// Returns a new collection created by merging the elements of the current one, with those of the other one.
    public func merging(with other: Self) -> Self {
        Self(
            quantityTypes: self.quantityTypes.union(other.quantityTypes),
            correlationTypes: self.correlationTypes.union(other.correlationTypes),
            categoryTypes: self.categoryTypes.union(other.categoryTypes)
        )
    }
    
    /// Merges the elements of the other collection into the current one.
    public mutating func merge(with other: Self) {
        self = self.merging(with: other)
    }
}


extension HealthKit.DataAccessRequirements {
    /// Initializes the object, based on the values in the other collection.
    public init(_ other: HealthSampleTypesCollection) {
        let sampleTypes = Set<HKSampleType> {
            other.quantityTypes.lazy.map(\.hkSampleType)
            other.categoryTypes.lazy.map(\.hkSampleType)
            other.correlationTypes.lazy.flatMap(\.associatedQuantityTypes).map(\.hkSampleType)
        }
        self.init(read: sampleTypes)
    }
}
