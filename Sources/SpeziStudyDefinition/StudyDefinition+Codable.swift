//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFoundation


extension StudyDefinition {
    private enum CodingKeysV0: String, CodingKey {
        case schemaVersion
        case studyRevision
        case metadata
        case components
        case componentSchedules
    }
    
    /// The configuration used to govern parts of the decoding process.
    public struct DecodingConfiguration {
        fileprivate let allowTrivialSchemaMigrations: Bool
        
        /// Creates a new `DecodingConfiguration`
        /// - parameter allowTrivialSchemaMigrations: Whether the decoding operation should be allowed to perform trivial migrations when decoding definitions encoded using an older schema version.
        public init(allowTrivialSchemaMigrations: Bool) {
            self.allowTrivialSchemaMigrations = allowTrivialSchemaMigrations
        }
    }
    
    /// Decodes a ``StudyDefinition`` from a `Decoder`, using the specified configuration.
    public init(from decoder: any Decoder, configuration: DecodingConfiguration) throws {
        // Q why not use made-up coding keys, to get just the schema, and then have the rest figured out dynamically?
        let container = try decoder.container(keyedBy: CodingKeysV0.self)
        let schemaVersion: Version
        do {
            schemaVersion = try container.decode(Version.self, forKey: .schemaVersion)
        } catch {
            if configuration.allowTrivialSchemaMigrations {
                schemaVersion = Self.schemaVersion
            } else {
                throw error
            }
        }
        switch schemaVersion {
        case Version(0, 2, 0):
            do {
                studyRevision = try container.decode(UInt.self, forKey: .studyRevision)
            } catch DecodingError.keyNotFound where configuration.allowTrivialSchemaMigrations {
                studyRevision = 0
            } catch {
                throw error
            }
            metadata = try container.decode(Metadata.self, forKey: .metadata)
            components = try container.decode([Component].self, forKey: .components)
            componentSchedules = try container.decode([ComponentSchedule].self, forKey: .componentSchedules)
        default:
            throw DecodingError.dataCorrupted(.init(
                codingPath: [],
                debugDescription: "Unsupported schema version: got \(schemaVersion); current is \(Self.schemaVersion)"
            ))
        }
    }
    
    
    /// Encodes a ``StudyDefinition`` into an `Encoder`.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeysV0.self)
        try container.encode(Self.schemaVersion, forKey: .schemaVersion)
        try container.encode(studyRevision, forKey: .studyRevision)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(components, forKey: .components)
        try container.encode(componentSchedules, forKey: .componentSchedules)
    }
}
