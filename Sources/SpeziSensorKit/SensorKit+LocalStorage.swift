//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import SpeziLocalStorage


extension SensorKit {
    // Essentially just a thread-safe dictionary that keeps track of our `LocalStorageKey`s used by the `SampleTypeScopedLocalStorage`.
    // The reason this exists is bc the LocalStorage API is intended to be used with long-lived LocalStorageKey objects, which doesn't easily
    // work with the multi-key scoping approach we're using here.
    // Were we not to use something like this for caching and re-using the keys, we'd need to create temporary `LocalStorageKey`s for
    // every load/store operation, which would of course work but would also defeat the whole purpose of having the `LocalStorageKey`s
    // be long-lived objects which are also used for e.g. locking / properly handling concurrent reads or writes.
    final class LocalStorageKeysStore<Value>: Sendable {
        private struct DictKey: Hashable {
            let valueType: String
            let sampleType: String
            
            init(sensor: some AnySensor<some Any>) {
                // this is fine bc we're not using it as a stable identifier
                // (the `valueType` key must only be valid&unique for the lifetime of the app)
                self.valueType = String(reflecting: Value.self)
                self.sampleType = sensor.id
            }
        }
        
        private let makeKey: @Sendable (any AnySensor) -> LocalStorageKey<Value>
        private let lock = RWLock()
        nonisolated(unsafe) private var keys: [DictKey: LocalStorageKey<Value>] = [:]
        
        init(makeKey: @escaping @Sendable (any AnySensor) -> LocalStorageKey<Value>) {
            self.makeKey = makeKey
        }
        
        func key(for sensor: some AnySensor<some Any>) -> LocalStorageKey<Value> {
            lock.withWriteLock {
                let dictKey = DictKey(sensor: sensor)
                if let key = keys[dictKey] {
                    return key
                } else {
                    let key = makeKey(sensor)
                    keys[dictKey] = key
                    return key
                }
            }
        }
    }
    
    
    struct SensorScopedLocalStorage<Value: SendableMetatype>: Sendable {
        private let localStorage: LocalStorage
        private let localStorageKeysStore: LocalStorageKeysStore<Value>
        
        init(localStorage: LocalStorage, localStorageKeysStore: LocalStorageKeysStore<Value>) {
            self.localStorage = localStorage
            self.localStorageKeysStore = localStorageKeysStore
        }
        
        private func storageKey(for sensor: Sensor<some Any>) -> LocalStorageKey<Value> {
            localStorageKeysStore.key(for: sensor)
        }
        
        subscript(sensor: Sensor<some Any>) -> Value? {
            get {
                try? localStorage.load(storageKey(for: sensor))
            }
            nonmutating set {
                try? localStorage.store(newValue, for: storageKey(for: sensor))
            }
        }
    }
}
