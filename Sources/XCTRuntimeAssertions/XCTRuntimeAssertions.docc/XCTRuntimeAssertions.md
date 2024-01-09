# ``XCTRuntimeAssertions``

Test assertions and preconditions using XCTest.

## Overview

This package allows developers to test assertions and preconditions in tests using XCTest.
This is done by overloading Swifts runtime assertions with the methods ``assert(_:_:file:line:)``, ``assertionFailure(_:file:line:)``, ``precondition(_:_:file:line:)``
and ``preconditionFailure(_:file:line:)``.
These are always called in your System under Test.
Only if requested within a unit test, their implementations are swapped to assert a runtime assertion.

### Configure your System under Test

To configure your System under Test, you just need to import the `XCTRuntimeAssertion` package and call your runtime assertions
functions as usual.

```swift
import XCTRuntimeAssertions

func foo() {
    precondition(someFooCondition, "Foo condition is unmet.")
    // ...
}
```

### Testing Runtime Assertions

In your unit tests you can use the ``XCTRuntimeAssertion(validateRuntimeAssertion:expectedFulfillmentCount:_:file:line:_:)-8wl0z`` and
``XCTRuntimePrecondition(validateRuntimeAssertion:timeout:_:file:line:_:)-g9jf`` functions to test a block of code for which you expect
a runtime assertion to occur.

Below is a short code example demonstrating this for assertions:

```swift
try XCTRuntimeAssertion {
    assertionFailure()
}
```

Below is a short code example demonstrating this for preconditions:

```swift
try XCTRuntimePrecondition {
    preconditionFailure()
}
```

> Tip: XCTRuntimeAssertion and XCTRuntimePrecondition also support the execution of async code.


## Topics

### Testing Assertions

- ``XCTRuntimeAssertion(validateRuntimeAssertion:expectedFulfillmentCount:_:file:line:_:)-8wl0z``
- ``XCTRuntimeAssertion(validateRuntimeAssertion:expectedFulfillmentCount:_:file:line:_:)-4y6wk``

### Testing Preconditions

- ``XCTRuntimePrecondition(validateRuntimeAssertion:timeout:_:file:line:_:)-g9jf``
- ``XCTRuntimePrecondition(validateRuntimeAssertion:timeout:_:file:line:_:)-62jjd``

### Errors

- ``XCTFail``

### Overloads

- ``assert(_:_:file:line:)``
- ``assertionFailure(_:file:line:)``
- ``precondition(_:_:file:line:)``
- ``preconditionFailure(_:file:line:)``
