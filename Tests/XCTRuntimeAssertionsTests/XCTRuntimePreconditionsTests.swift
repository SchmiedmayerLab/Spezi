//
// This source file is part of the Stanford RuntimeAssertions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import RuntimeAssertions
import XCTest
@testable import XCTRuntimeAssertions


final class XCTRuntimePreconditionsTests: XCTestCase {
    func testXCTRuntimePrecondition() throws {
        let expectation = XCTestExpectation(description: "validateRuntimeAssertion")
        expectation.assertForOverFulfill = true
        
        let number = 42
        
        XCTAssertRuntimePrecondition(
            validateRuntimeAssertion: {
                XCTAssertEqual("preconditionFailure()", $0)
                expectation.fulfill()
            },
            "testXCTRuntimePrecondition"
        ) {
            precondition(number != 42, "preconditionFailure()")
        }

        wait(for: [expectation], timeout: 0.01)
        
        
        XCTAssertRuntimePrecondition(validateRuntimeAssertion: { XCTAssertEqual($0, "") }) {
            preconditionFailure()
        }
        
        XCTAssertRuntimePrecondition {
            preconditionFailure()
        }
    }
    
    func testAsyncXCTRuntimePrecondition() throws {
        let expectation = XCTestExpectation(description: "validateRuntimePrecondition")
        expectation.assertForOverFulfill = true
        
        XCTAssertRuntimePrecondition(
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

        XCTExpectFailure {
            XCTAssertRuntimePrecondition {
                print("Hello Paul 👋")
            }
        }

        XCTExpectFailure {
            XCTAssertRuntimePrecondition {
                Task {
                    preconditionFailure()
                }
                preconditionFailure()
            }
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

        XCTAssertRuntimePrecondition {
            precondition(test.property != "Hello World", "Failed successfully.")
        }
    }
    
    func testNoPrecondition() {
        XCTAssertNoRuntimePrecondition {
            // nothing going on in here
        }
    }
    
    func testNoPreconditionAsync() {
        XCTAssertNoRuntimePrecondition { () async in
            // nothing going on in here
        }
    }
}
