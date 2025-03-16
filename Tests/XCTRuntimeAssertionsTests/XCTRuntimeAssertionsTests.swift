//
// This source file is part of the Stanford RuntimeAssertions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import XCTRuntimeAssertions


final class XCTRuntimeAssertionsTests: XCTestCase {
    func testXCTRuntimeAssertion() throws {
        struct XCTRuntimeAssertionError: Error {}
        
        
        let messages = [
            "assertionFailure()",
            "assert(false)",
            "assert(42 == 42)"
        ]
        nonisolated(unsafe) var collectedMessages: [String] = []
        let number = 42
        
        XCTRuntimeAssertion(
            validateRuntimeAssertion: {
                collectedMessages.append($0)
            },
            expectedFulfillmentCount: 3,
            "testXCTRuntimeAssertion"
        ) {
            assertionFailure(messages[0])
            assert(false, messages[1])
            assert(number != 42, messages[2])
        }
        
        XCTAssertEqual(messages, collectedMessages)
        
        XCTRuntimeAssertion(validateRuntimeAssertion: { XCTAssertEqual($0, "") }) {
            assertionFailure()
        }
        
        XCTRuntimeAssertion {
            assertionFailure()
        }
        
        do {
            try XCTRuntimeAssertion {
                assertionFailure()
                throw XCTRuntimeAssertionError()
            }
        } catch is XCTRuntimeAssertionError {
            return
        }
    }
    
    func testAsyncXCTRuntimeAssertion() async throws {
        let expectation = XCTestExpectation(description: "validateRuntimeAssertion")
        expectation.assertForOverFulfill = true
        
        try await XCTRuntimeAssertion(
            validateRuntimeAssertion: {
                XCTAssertEqual($0, "assertionFailure()")
                expectation.fulfill()
            },
            expectedFulfillmentCount: 1,
            "testXCTRuntimeAssertion"
        ) {
            try await Task.sleep(for: .seconds(0.02))
            assertionFailure("assertionFailure()")
            try await Task.sleep(for: .seconds(0.02))
        }
        
        await fulfillment(of: [expectation], timeout: 0.1)
    }
    
    func testXCTRuntimeAssertionNotTriggered() throws {
        struct XCTRuntimeAssertionNotTriggeredError: Error {}

        XCTExpectFailure {
            let result = XCTRuntimeAssertion {
                "Hello Paul 👋"
            }
            XCTAssertEqual(result, "Hello Paul 👋")
        }


        try XCTAssertThrowsError({
            try XCTExpectFailure {
                try XCTRuntimeAssertion {
                    throw XCTRuntimeAssertionNotTriggeredError()
                }
            }
        }())
    }

    func testCallHappensWithoutInjection() {
        var called = false

        assert({
            called = true
            return true
        }(), "This could fail")

        XCTAssertTrue(called, "assert was never called!")
    }

    @MainActor
    func testActorAnnotatedClosure() throws {
        @MainActor
        class Test {
            var property = "Hello World"

            nonisolated init() {}
        }

        let test = Test()

        XCTRuntimeAssertion {
            assert(test.property != "Hello World", "Failed successfully")
        }
    }
}
