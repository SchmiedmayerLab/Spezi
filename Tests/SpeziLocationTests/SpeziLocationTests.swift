//
// This source file is part of the SpeziLocation open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLocation
import XCTest


final class SpeziLocationTests: XCTestCase {
    func testSpeziLocation() throws {
        let speziLocation = SpeziLocation()
        XCTAssertEqual(speziLocation.stanford, "Stanford University")
    }
}
