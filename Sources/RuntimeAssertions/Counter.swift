//
// This source file is part of the Stanford RuntimeAssertions open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


package final class Counter: Sendable {
    private nonisolated(unsafe) var counter: Int
    private let lock = NSLock()

    package var count: Int {
        lock.withLock {
            counter
        }
    }

    
    package init(counter: Int = 0) {
        self.counter = counter
    }

    package func increment() {
        lock.withLock {
            counter += 1
        }
    }
}
