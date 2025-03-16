//
// This source file is part of the Stanford RuntimeAssertions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Execute a block of code only in debug builds.
/// - Parameters:
///   - block: The block to execute in debug builds.
///   - else: The block to execute in release builds.
@inlinable
func debugOnly(_ block: () -> Void, else: () -> Void = {}) {
    // we abuse the power of assert to optimize out our call to `block`
    var called = false
    Swift.assert({
        block()
        called = true
        return true
    }())

    if !called {
        `else`()
    }
}
