//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziMedication
import XCTest


final class SpeziMedicationTests: XCTestCase {
    func testSpeziMedication() throws {
        let speziMedication = SpeziMedication()
        XCTAssertEqual(speziMedication.stanford, "Stanford University")
    }
}
