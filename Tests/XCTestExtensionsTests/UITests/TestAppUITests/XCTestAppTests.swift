//
// This source file is part of the XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


class XCTestAppTests: XCTestCase {
    func testTestAppTestCaseTest() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.staticTexts["XCTestApp"].tap()
        
        XCTAssert(app.staticTexts["Passed"].waitForExistence(timeout: 5))
    }
}
