//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
import SpeziLocalStorage


/// Used to keep track of previously-fetched SensorKit samples to avoid duplicates when querying data.
struct QueryAnchor: Hashable, Codable, Sendable {
    /// The most-recent point in time for which data was queried.
    ///
    /// Note that this refers to the upper bound of the time range *for* which data was queried, not the point in time *at* which the query took place.
    let timestamp: Date
    
    /// Creates a new, empty `QueryAnchor`.
    init() {
        self.timestamp = .distantPast
    }
    
    /// Creates a new `QueryAnchor` for the specified timestamp.
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        timestamp = try container.decode(Date.self)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(timestamp)
    }
}


/// A `QueryAnchor` that is backed using Spezi LocalStorage.
final class ManagedQueryAnchor: Sendable {
    private let get: @Sendable () throws -> QueryAnchor
    private let set: @Sendable (QueryAnchor) throws -> Void
    
    var value: QueryAnchor {
        get throws {
            try get()
        }
    }
    
    init(storageKey: LocalStorageKey<QueryAnchor>, in localStorage: LocalStorage) {
        get = { try localStorage.load(storageKey) ?? QueryAnchor() }
        set = { try localStorage.store($0, for: storageKey) }
    }
    
    func update(_ newValue: QueryAnchor) throws {
        if let oldValue = try? get(), oldValue == newValue {
            return
        }
        try set(newValue)
    }
}
