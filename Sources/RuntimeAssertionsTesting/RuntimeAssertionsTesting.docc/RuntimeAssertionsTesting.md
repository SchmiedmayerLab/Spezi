# ``RuntimeAssertionsTesting``

<!--

This source file is part of the Stanford RuntimeAssertions open-source project

SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT

-->

Test assertions and preconditions using Swift Testing.

## Overview

This package allows developers to test assertions and preconditions in tests using Swift Testing.

> Note: Make sure to use the `RuntimeAssertions` runtime support in your system under test.

### Testing Runtime Assertions

In your unit tests you can use the ``expectRuntimeAssertion(expectedCount:_:assertion:sourceLocation:_:)-62s7y`` and
``expectRuntimePrecondition(timeout:_:precondition:sourceLocation:_:)-96i1f`` functions to test a block of code for which you expect
a runtime assertion to occur.

Below is a short code example demonstrating this for assertions:

```swift
import RuntimeAssertionsTesting
import Testing

@Test
func testAssertion() {
    expectRuntimeAssertion {
        // code containing a call to assert() of the runtime support ...
    }
}
```

Below is a short code example demonstrating this for preconditions:

```swift
import RuntimeAssertionsTesting
import Testing

@Test
func testPrecondition() {
    expectRuntimePrecondition {
        // code containing a call to precondition() of the runtime support ...
    }
}
```

> Tip: Both expectation methods also support the execution of `async` code.


## Topics

### Testing Assertions

- ``expectRuntimeAssertion(expectedCount:_:assertion:sourceLocation:_:)-62s7y``
- ``expectRuntimeAssertion(expectedCount:_:assertion:sourceLocation:_:)-8hn1j``

### Testing Preconditions

- ``expectRuntimePrecondition(timeout:_:precondition:sourceLocation:_:)-96i1f``
- ``expectRuntimePrecondition(timeout:_:precondition:sourceLocation:_:)-60tb0``

