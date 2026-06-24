<!--

This source file is part of the Stanford RuntimeAssertions open-source project.

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT

-->

# RuntimeAssertions


Test assertions and preconditions.


## Overview

This library provides the necessary runtime support to support unit testing assertions and preconditions.
The library overloads Swifts runtime assertions:
* `assert(_:_:file:line:)`
* `assertionFailure(_:file:line:)`
* `precondition(_:_:file:line:)`
* `preconditionFailure(_:file:line:)`

Always call this method in your System under Test.
Only if requested within a unit test, their implementations are swapped to assert a runtime assertion.
Release builds will completely optimize out this runtime support library and direct calls to the original Swift implementation.

### Configure your System under Test

To configure your System under Test, you just need to import the `RuntimeAssertion` library and call your runtime assertions functions as usual.

```swift
import RuntimeAssertions

func foo() {
    precondition(someFooCondition, "Foo condition is unmet.")
    // ...
}
```

### Testing Runtime Assertions

In your unit tests you can use the `expectRuntimeAssertion(expectedCount:_:assertion:sourceLocation:_:)` and
`expectRuntimePrecondition(timeout:_:precondition:sourceLocation:_:)` functions to test a block of code for which you expect
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

Import the `RuntimeAssertionsTesting` module if you use Swift Testing; import `XCTRuntimeAssertions` if you use XCTest.

> Important: Don't import `RuntimeAssertionsTesting` or `XCTRuntimeAssertions` in your application target.

## Contributing

Contributions to this project are welcome. Please make sure to read the [contribution guide](../Spezi/Spezi.docc/Contributing%20Guide.md) and the [Contributor Covenant Code of Conduct](https://github.com/SchmiedmayerLab/.github/blob/main/CODE_OF_CONDUCT.md) first.

## License

This target is licensed under the MIT License. The local [LICENSES](LICENSES) directory records license information imported from the original upstream repository. See the monorepo [LICENSES](../../LICENSES) directory for license information covering current changes in this repository.


## Contributors

The local [CONTRIBUTORS.md](CONTRIBUTORS.md) file records contributors from the original upstream repository. See the monorepo [CONTRIBUTORS.md](../../CONTRIBUTORS.md) file for contributors to current changes in this repository.
