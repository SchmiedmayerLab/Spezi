//
// This source file is part of the Stanford RuntimeAssertions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import RuntimeAssertions
#if canImport(XCTest)
import XCTest
#endif


/// `XCTRuntimePrecondition` allows you to test assertions of types that use the `precondition` and `preconditionFailure` functions of the `XCTRuntimeAssertions` target.
///
/// - Important: The `expression` is executed on a background thread, even though it is not annotated as `@Sendable`. This is by design. Preconditions return `Never` and, therefore,
/// need to be run on a separate thread that can block forever. Without this workaround, testing preconditions that are isolated to `@MainActor` would be impossible.
/// Make sure to only run isolated parts of your code that don't suffer from concurrency issues in such a scenario.
///
/// - Parameters:
///   - validateRuntimeAssertion: An optional closure that can be used to further validate the messages passed to the
///                               `precondition` and `preconditionFailure` functions of the `XCTRuntimeAssertions` target.
///   - timeout: A timeout defining how long to wait for the precondition to be triggered.
///   - message: A message that is posted on failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call this function.
///   - expression: The expression that is evaluated.
public func XCTRuntimePrecondition(
    validateRuntimeAssertion: (@Sendable (String) -> Void)? = nil,
    timeout: TimeInterval = 2,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ expression: @escaping () -> Void
) {
    withRuntimePrecondition(timeout: timeout, validatePrecondition: validateRuntimeAssertion, expression) { count in
        assertFulfillmentCount(count, message, file: file, line: line)
    }
}

/// `XCTRuntimePrecondition` allows you to test async assertions of types that use the `precondition` and `preconditionFailure` functions of the `XCTRuntimeAssertions` target.
///
/// - Important: The `expression` is executed on a background thread, even though it is not annotated as `@Sendable`. This is by design. Preconditions return `Never` and, therefore,
/// need to be run on a separate thread that can block forever. Without this workaround, testing preconditions that are isolated to `@MainActor` would be impossible.
/// Make sure to only run isolated parts of your code that don't suffer from concurrency issues in such a scenario.
///
/// - Parameters:
///   - validateRuntimeAssertion: An optional closure that can be used to further validate the messages passed to the
///                               `precondition` and `preconditionFailure` functions of the `XCTRuntimeAssertions` target.
///   - timeout: A timeout defining how long to wait for the precondition to be triggered.
///   - message: A message that is posted on failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call this function.
///   - expression: The async expression that is evaluated.
public func XCTRuntimePrecondition(
    validateRuntimeAssertion: (@Sendable (String) -> Void)? = nil,
    timeout: TimeInterval = 2,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ expression: @escaping () async -> Void
) throws {
    withRuntimePrecondition(timeout: timeout, validatePrecondition: validateRuntimeAssertion, expression) { count in
        assertFulfillmentCount(count, message, file: file, line: line)
    }
}


private func assertFulfillmentCount(
    _ fulfillmentCount: Int,
    _ message: () -> String,
    file: StaticString,
    line: UInt
) {
#if canImport(XCTest)
    if fulfillmentCount <= 0 {
        XCTFail(
            """
            The precondition was never called.
            \(message()) at \(file):\(line)
            """
        )
    } else if fulfillmentCount > 1 {
        XCTFail(
            """
            The precondition was called multiple times (\(fulfillmentCount)).
            \(message()) at \(file):\(line)
            """
        )
    }
#endif
}
