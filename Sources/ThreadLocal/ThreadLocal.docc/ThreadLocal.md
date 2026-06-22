# ``ThreadLocal``

<!--
#
# This source file is part of the ThreadLocal open source project
#
# SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#       
-->

Thread-local variables for Swift.

## Overview

Use the ``ThreadLocal()`` macro to define a thread-local static variable:
```swift
extension SomeType {
    @ThreadLocal
    private static var counter: Int = 0
}
```
Each thread will have its own version of the variable.
On each thread, the variable is initially initialized to its default value (0 in the example above).
When the thread is destroyed, the variable's lifetime is ended.

You can use non-trivial types with thread-local variables, and can provide a custom deallocator if needed (see ``ThreadLocal(deallocator:)``).

### Limitations
Swift already provides [`TaskLocal`](https://developer.apple.com/documentation/swift/tasklocal) as a mechanism for defining task-local variables, which have their value bound to the specific `Task` from which they are accessed.

If your code is `async` or makes in any way use of Swift Concurrency, **always** use [`TaskLocal`](https://developer.apple.com/documentation/swift/tasklocal) instead of this package.

Unless a function is explicitly bound to a global actor, any suspension point within the function may lead to the function hopping onto a different thread.
If an `async` function interacts with `ThreadLocal` variables, accessing a thread-local variable after passing a suspension point will access a different variable than an access before the suspension point, leading to unexpected and unmanageable issues in your program.

The `ThreadLocal` mechanism implemented by this package is intended exclusively for use from non-async functions, which are guarenteed to stay on the same thread for their entire execution.
You can of course still access a `@ThreadLocal` definition from multiple threads concurrently.
Only use this library and the ``ThreadLocal()`` macro if you know what you're doing and if this is your exact use case.

- Warning: Only use ``ThreadLocal()`` in non-async functions and only if [`TaskLocal`](https://developer.apple.com/documentation/swift/tasklocal) or other mechanisms have proven to not work for your specific use case.


## Topics

### Macros
- ``ThreadLocal()``
- ``ThreadLocal(deallocator:)``

### Supporting Types
- ``ThreadLocal``
