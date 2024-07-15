//
// This source file is part of the Stanford XCTRuntimeAssertions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import XCTRuntimeAssertions


final class XCTRuntimePreconditionsTests: XCTestCase {
    func testXCTRuntimePrecondition() throws {
        let expectation = XCTestExpectation(description: "validateRuntimeAssertion")
        expectation.assertForOverFulfill = true
        
        let number = 42
        
        try XCTRuntimePrecondition(
            validateRuntimeAssertion: {
                XCTAssertEqual("preconditionFailure()", $0)
                expectation.fulfill()
            },
            "testXCTRuntimePrecondition"
        ) {
            precondition(number != 42, "preconditionFailure()")
        }

        wait(for: [expectation], timeout: 0.01)
        
        
        try XCTRuntimePrecondition(validateRuntimeAssertion: { XCTAssertEqual($0, "") }) {
            preconditionFailure()
        }
        
        try XCTRuntimePrecondition {
            preconditionFailure()
        }
    }
    
    func testAsyncXCTRuntimePrecondition() throws {
        let expectation = XCTestExpectation(description: "validateRuntimePrecondition")
        expectation.assertForOverFulfill = true
        
        try XCTRuntimePrecondition(
            validateRuntimeAssertion: {
                XCTAssertEqual($0, "preconditionFailure()")
                expectation.fulfill()
            },
            timeout: 0.5,
            "testXCTRuntimePrecondition"
        ) {
            try? await Task.sleep(for: .seconds(0.02))
            preconditionFailure("preconditionFailure()")
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testXCTRuntimePreconditionNotTriggered() async throws {
        struct XCTRuntimePreconditionNotTriggeredError: Error {}
        
        do {
            try XCTRuntimePrecondition {
                print("Hello Paul 👋")
            }
        } catch let error as XCTFail {
            XCTAssertTrue(error.message.contains("The precondition was never called."))
        }
        
        do {
            try XCTRuntimePrecondition {
                Task {
                    preconditionFailure()
                }
                preconditionFailure()
            }
        } catch let error as XCTFail {
            try? await Task.sleep(for: .seconds(0.5))
            XCTAssertTrue(error.description.contains("The precondition was called multiple times."))
        }
    }

    func testCallHappensWithoutInjection() {
        var called = false

        precondition({
            called = true
            return true
        }(), "This could fail")

        XCTAssertTrue(called, "precondition was never called!")
    }

    @MainActor
    func testAsyncInvocationOnMainActor() throws {
        @MainActor
        class Test {
            var property = "Hello World"
        }

        let test = Test()

        try XCTRuntimePrecondition {
            precondition(test.property != "Hello World", "Failed successfully.")
        }
    }
}
