//
// This source file is part of the Stanford RuntimeAssertions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import RuntimeAssertions
import XCTest


/// `XCTRuntimeAssertion` allows you to test assertions of types that use the `assert` and `assertionFailure` functions of the `XCTRuntimeAssertions` target.
/// - Parameters:
///   - validateRuntimeAssertion: An optional closure that can be used to further validate the messages passed to the
///                               `assert` and `assertionFailure` functions of the `XCTRuntimeAssertions` target.
///   - expectedFulfillmentCount: The expected fulfillment count on how often the `assert` and `assertionFailure` functions of
///                               the `XCTRuntimeAssertions` target are called. The default value is 1. The value must be non-zero.
///   - message: A message that is posted on failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call this function.
///   - expression: The expression that is evaluated.
public func XCTRuntimeAssertion<T, E: Error>(
    validateRuntimeAssertion: (@Sendable (String) -> Void)? = nil,
    expectedFulfillmentCount: UInt = 1,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ expression: () throws(E) -> T
) throws(E) -> T {
    try withRuntimeAssertion(validateAssertion: validateRuntimeAssertion, expression) { count in
        assertFulfillmentCount(count, expectedFulfillmentCount: expectedFulfillmentCount, message, file: file, line: line)
    }
}

/// `XCTRuntimeAssertion` allows you to test async assertions of types that use the `assert` and `assertionFailure` functions of the `XCTRuntimeAssertions` target.
/// - Parameters:
///   - validateRuntimeAssertion: An optional closure that can be used to further validate the messages passed to the
///                               `assert` and `assertionFailure` functions of the `XCTRuntimeAssertions` target.
///   - expectedFulfillmentCount: The expected fulfillment count on how often the `assert` and `assertionFailure` functions of
///                               the `XCTRuntimeAssertions` target are called. The default value is 1. The value must be non-zero.
///   - message: A message that is posted on failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call this function.
///   - expression: The async expression that is evaluated.
public func XCTRuntimeAssertion<T, E: Error>(
    validateRuntimeAssertion: (@Sendable (String) -> Void)? = nil,
    expectedFulfillmentCount: UInt = 1,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ expression: () async throws(E) -> T
) async throws(E) -> T {
    try await withRuntimeAssertion(validateAssertion: validateRuntimeAssertion, expression) { count in
        assertFulfillmentCount(count, expectedFulfillmentCount: expectedFulfillmentCount, message, file: file, line: line)
    }
}


private func assertFulfillmentCount(
    _ fulfillmentCount: Int,
    expectedFulfillmentCount: UInt,
    _ message: () -> String,
    file: StaticString,
    line: UInt
) {
    Swift.precondition(expectedFulfillmentCount > 0, "expectedFulfillmentCount has to be non-zero!")
    if fulfillmentCount != expectedFulfillmentCount {
        XCTFail(
             """
             Measured an fulfillment count of \(fulfillmentCount), expected \(expectedFulfillmentCount).
             \(message()) at \(file):\(line)
             """
        )
    }
}
