//
// This source file is part of the Stanford XCTRuntimeAssertions open-source project
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
        var collectedMessages: [String] = []
        let number = 42
        
        try XCTRuntimeAssertion(
            validateRuntimeAssertion: {
                collectedMessages.append($0)
            },
            expectedFulfillmentCount: 3,
            "testXCTRuntimeAssertion"
        ) {
            assertionFailure(messages[0])
            assert(true, messages[1])
            assert(number == 42, messages[2])
        }
        
        XCTAssertEqual(messages, collectedMessages)
        
        try XCTRuntimeAssertion(validateRuntimeAssertion: { XCTAssertEqual($0, "") }) {
            assertionFailure()
        }
        
        try XCTRuntimeAssertion {
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
    
    func testXCTRuntimeAssertationNotTriggered() throws {
        struct XCTRuntimeAssertionNotTriggeredError: Error {}
        
        do {
            let result = try XCTRuntimeAssertion {
                "Hello Paul 👋"
            }
            XCTAssertEqual(result, "Hello Paul 👋")
        } catch let error as XCTFail {
            XCTAssertTrue(error.message.contains("Measured an fulfillment count of 0, expected 1."))
        }
        
        do {
            try XCTRuntimeAssertion {
                throw XCTRuntimeAssertionNotTriggeredError()
            }
        } catch let error as XCTFail {
            XCTAssertTrue(error.description.contains("Measured an fulfillment count of 0, expected 1."))
        }
    }
}
