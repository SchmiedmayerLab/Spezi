//
// This source file is part of the Stanford XCTRuntimeAssertions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if DEBUG || TEST
import Foundation


private final class RuntimeInjections: Sendable {
    private nonisolated(unsafe) var injected: [XCTRuntimeAssertionInjector] = []
    private let lock = NSLock()

    @inlinable var isEmpty: Bool {
        injected.isEmpty
    }

    var injections: [XCTRuntimeAssertionInjector] {
        lock.withLock {
            injected
        }
    }

    init() {}

    func append(_ element: XCTRuntimeAssertionInjector) {
        lock.withLock {
            injected.append(element)
        }
    }

    func removeAll(for id: UUID) {
        lock.withLock {
            injected.removeAll(where: { $0.id == id })
        }
    }
}


class XCTRuntimeAssertionInjector {
    private static let injection = RuntimeInjections()

    
    let id: UUID
    private let _assert: (UUID, () -> Bool, () -> String, StaticString, UInt) -> Void
    private let _precondition: (UUID, () -> Bool, () -> String, StaticString, UInt) -> Void
    
    
    init(
        id: UUID,
        assert: @escaping (UUID, () -> Bool, () -> String, StaticString, UInt) -> Void,
        precondition: @escaping (UUID, () -> Bool, () -> String, StaticString, UInt) -> Void
    ) {
        self.id = id
        self._assert = assert
        self._precondition = precondition
    }
    
    init(
        id: UUID,
        assert: @escaping (UUID, () -> Bool, () -> String, StaticString, UInt) -> Void
    ) {
        self.id = id
        self._assert = assert
        self._precondition = { _, condition, message, file, line in
            Swift.precondition(condition(), message(), file: file, line: line)
        }
    }
    
    init(
        id: UUID,
        precondition: @escaping (UUID, () -> Bool, () -> String, StaticString, UInt) -> Void
    ) {
        self.id = id
        self._assert = { _, condition, message, file, line in
            Swift.assert(condition(), message(), file: file, line: line)
        }
        self._precondition = precondition
    }
    
    init(
        id: UUID
    ) {
        self.id = id
        self._assert = { _, condition, message, file, line in
            Swift.assert(condition(), message(), file: file, line: line)
        }
        self._precondition = { _, condition, message, file, line in
            Swift.precondition(condition(), message(), file: file, line: line)
        }
    }
    
    
    static func inject(runtimeAssertionInjector: XCTRuntimeAssertionInjector) {
        injection.append(runtimeAssertionInjector)
    }
    
    static func removeRuntimeAssertionInjector(withId id: UUID) {
        injection.removeAll(for: id)
    }
    

    @inlinable
    static func assert(_ condition: () -> Bool, message: () -> String, file: StaticString, line: UInt) {
        if injection.isEmpty {
            Swift.assert(condition(), message(), file: file, line: line)
        }

        for runtimeAssertionInjector in injection.injections {
            runtimeAssertionInjector._assert(runtimeAssertionInjector.id, condition, message, file, line)
        }
    }

    @inlinable
    static func precondition(_ condition: () -> Bool, message: () -> String, file: StaticString, line: UInt) {
        if injection.isEmpty {
            Swift.precondition(condition(), message(), file: file, line: line)
        }

        for runtimeAssertionInjector in injection.injections {
            runtimeAssertionInjector._precondition(runtimeAssertionInjector.id, condition, message, file, line)
        }
    }
}
#endif
