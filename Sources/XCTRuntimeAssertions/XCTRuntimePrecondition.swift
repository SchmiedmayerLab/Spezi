//
// This source file is part of the Stanford XCTRuntimeAssertions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if DEBUG || TEST
import Foundation


/// `XCTRuntimePrecondition` allows you to test assertions of types that use the `precondition` and `preconditionFailure` functions of the `XCTRuntimeAssertions` target.
/// - Parameters:
///   - validateRuntimeAssertion: An optional closure that can be used to further validate the messages passed to the
///                               `precondition` and `preconditionFailure` functions of the `XCTRuntimeAssertions` target.
///   - timeout: A timeout defining how long to wait for the precondition to be triggered.
///   - message: A message that is posted on failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call this function.
///   - expression: The expression that is evaluated.
/// - Throws: Throws an `XCTFail` error if the expression does not trigger a runtime assertion with the parameters defined above.
public func XCTRuntimePrecondition(
    validateRuntimeAssertion: ((String) -> Void)? = nil,
    timeout: Double = 0.01,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ expression: @escaping () -> Void
) throws {
    let fulfillmentCount = Counter()
    let xctRuntimeAssertionId = setupXCTRuntimeAssertionInjector(
        fulfillmentCount: fulfillmentCount,
        validateRuntimeAssertion: validateRuntimeAssertion
    )
    
    // We have to run the operation on a `DispatchQueue` as we have to call `RunLoop.current.run()` in the `preconditionFailure` call.
    let dispatchQueue = DispatchQueue(label: "XCTRuntimePrecondition-\(xctRuntimeAssertionId)")
    
    let expressionWorkItem = DispatchWorkItem {
        expression()
    }
    dispatchQueue.async(execute: expressionWorkItem)
    
    // We don't use:
    // `wait(for: [expectation], timeout: timeout)`
    // here as we need to make the method independent of XCTestCase to also use it in our TestApp UITest target which fails if you import XCTest.
    usleep(useconds_t(1_000_000 * timeout))
    expressionWorkItem.cancel()
    
    XCTRuntimeAssertionInjector.removeRuntimeAssertionInjector(withId: xctRuntimeAssertionId)

    try assertFulfillmentCount(
        fulfillmentCount,
        message,
        file: file,
        line: line
    )
}

/// `XCTRuntimePrecondition` allows you to test async assertions of types that use the `precondition` and `preconditionFailure` functions of the `XCTRuntimeAssertions` target.
/// - Parameters:
///   - validateRuntimeAssertion: An optional closure that can be used to further validate the messages passed to the
///                               `precondition` and `preconditionFailure` functions of the `XCTRuntimeAssertions` target.
///   - timeout: A timeout defining how long to wait for the precondition to be triggered.
///   - message: A message that is posted on failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call this function.
///   - expression: The async expression that is evaluated.
/// - Throws: Throws an `XCTFail` error if the expression does not trigger a runtime assertion with the parameters defined above.
public func XCTRuntimePrecondition(
    validateRuntimeAssertion: ((String) -> Void)? = nil,
    timeout: Double = 0.01,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ expression: @escaping () async -> Void
) throws {
    let fulfillmentCount = Counter()
    let xctRuntimeAssertionId = setupXCTRuntimeAssertionInjector(
        fulfillmentCount: fulfillmentCount,
        validateRuntimeAssertion: validateRuntimeAssertion
    )
    
    let task = Task {
        await expression()
    }
    
    // We don't use:
    // `wait(for: [expectation], timeout: timeout)`
    // here as we need to make the method independent of XCTestCase to also use it in our TestApp UITest target which fails if you import XCTest.
    usleep(useconds_t(1_000_000 * timeout))
    task.cancel()
    
    XCTRuntimeAssertionInjector.removeRuntimeAssertionInjector(withId: xctRuntimeAssertionId)

    try assertFulfillmentCount(
        fulfillmentCount,
        message,
        file: file,
        line: line
    )
}


private func setupXCTRuntimeAssertionInjector(fulfillmentCount: Counter, validateRuntimeAssertion: ((String) -> Void)? = nil) -> UUID {
    let xctRuntimeAssertionId = UUID()
    
    XCTRuntimeAssertionInjector.inject(
        runtimeAssertionInjector: XCTRuntimeAssertionInjector(
            id: xctRuntimeAssertionId,
            precondition: { id, condition, message, _, _  in
                guard id == xctRuntimeAssertionId else {
                    return
                }
                
                if !condition() {
                    // We execute the message closure independent of the availability of the `validateRuntimeAssertion` closure.
                    let message = message()
                    validateRuntimeAssertion?(message)
                    fulfillmentCount.counter += 1
                    neverReturn()
                }
            }
        )
    )
    
    return xctRuntimeAssertionId
}

private func assertFulfillmentCount(
    _ fulfillmentCount: Counter,
    _ message: () -> String,
    file: StaticString,
    line: UInt
) throws {
    if fulfillmentCount.counter <= 0 {
        throw XCTFail(
            message: """
            The precondition was never called.
            \(message()) at \(file):\(line)
            """
        )
    } else if fulfillmentCount.counter > 1 {
        throw XCTFail(
            message: """
            The precondition was called multiple times.
            \(message()) at \(file):\(line)
            """
        )
    }
}
#endif
