//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


extension XCUIApplication {
    func buttonTap(_ identifier: String) {
        XCTAssertTrue(buttons[identifier].waitForExistence(timeout: 2))
        sleep(1)
        buttons[identifier].tap()
    }
}
