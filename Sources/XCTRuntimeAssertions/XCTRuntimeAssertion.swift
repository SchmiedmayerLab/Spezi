//
// This source file is part of the Stanford XCTRuntimeAssertions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if DEBUG || TEST
import Foundation


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
/// - Throws: Throws an `XCTFail` error if the expression does not trigger a runtime assertion with the parameters defined above.
/// - Returns: The value of the function if it did not throw an error as it did not trigger a runtime assertion with the parameters defined above.
public func XCTRuntimeAssertion<T>(
    validateRuntimeAssertion: ((String) -> Void)? = nil,
    expectedFulfillmentCount: UInt = 1,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ expression: @escaping () throws -> T
) throws -> T {
    let fulfillmentCount = Counter()
    let xctRuntimeAssertionId = setupXCTRuntimeAssertionInjector(
        fulfillmentCount: fulfillmentCount,
        validateRuntimeAssertion: validateRuntimeAssertion
    )

    var result: Result<T, Error>
    do {
        result = .success(try expression())
    } catch {
        result = .failure(error)
    }

    XCTRuntimeAssertionInjector.removeRuntimeAssertionInjector(withId: xctRuntimeAssertionId)

    try assertFulfillmentCount(
        fulfillmentCount,
        expectedFulfillmentCount: expectedFulfillmentCount,
        message,
        file: file,
        line: line
    )

    switch result {
    case let .success(returnValue):
        return returnValue
    case let .failure(error):
        throw error
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
/// - Throws: Throws an `XCTFail` error if the expression does not trigger a runtime assertion with the parameters defined above.
/// - Returns: The value of the function if it did not throw an error as it did not trigger a runtime assertion with the parameters defined above.
public func XCTRuntimeAssertion<T>(
    validateRuntimeAssertion: ((String) -> Void)? = nil,
    expectedFulfillmentCount: UInt = 1,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ expression: @escaping () async throws -> T
) async throws -> T {
    let fulfillmentCount = Counter()
    let xctRuntimeAssertionId = setupXCTRuntimeAssertionInjector(
        fulfillmentCount: fulfillmentCount,
        validateRuntimeAssertion: validateRuntimeAssertion
    )

    var result: Result<T, Error>
    do {
        result = .success(try await expression())
    } catch {
        result = .failure(error)
    }

    XCTRuntimeAssertionInjector.removeRuntimeAssertionInjector(withId: xctRuntimeAssertionId)

    try assertFulfillmentCount(
        fulfillmentCount,
        expectedFulfillmentCount: expectedFulfillmentCount,
        message,
        file: file,
        line: line
    )

    switch result {
    case let .success(returnValue):
        return returnValue
    case let .failure(error):
        throw error
    }
}


private func setupXCTRuntimeAssertionInjector(fulfillmentCount: Counter, validateRuntimeAssertion: ((String) -> Void)? = nil) -> UUID {
    let xctRuntimeAssertionId = UUID()

    XCTRuntimeAssertionInjector.inject(
        runtimeAssertionInjector: XCTRuntimeAssertionInjector(
            id: xctRuntimeAssertionId,
            assert: { id, condition, message, _, _  in
                guard id == xctRuntimeAssertionId else {
                    return
                }
                
                if !condition() {
                    // We execute the message closure independent of the availability of the `validateRuntimeAssertion` closure.
                    let message = message()
                    validateRuntimeAssertion?(message)
                    fulfillmentCount.counter += 1
                }
            }
        )
    )

    return xctRuntimeAssertionId
}


private func assertFulfillmentCount(
    _ fulfillmentCount: Counter,
    expectedFulfillmentCount: UInt,
    _ message: () -> String,
    file: StaticString,
    line: UInt
) throws {
    Swift.precondition(expectedFulfillmentCount > 0, "expectedFulfillmentCount has to be non-zero!")

    if fulfillmentCount.counter != expectedFulfillmentCount {
        throw XCTFail(
            message: """
                     Measured an fulfillment count of \(fulfillmentCount.counter), expected \(expectedFulfillmentCount).
                     \(message()) at \(file):\(line)
                     """
        )
    }
}
#endif
