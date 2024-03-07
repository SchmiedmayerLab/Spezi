//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


func verifyAsciiInput<Value: BinaryInteger>(_ value: Value, maxLength: Int, for field: String) throws {
    try verifyAsciiInput(value.description, maxLength: maxLength, for: field)
}


func verifyAsciiInput(_ value: String, maxLength: Int, for field: String) throws {
    if value.count > maxLength {
        throw EDFEncodingError.inputTooLong(field: field, value, expectedLength: maxLength)
    }

    for character in value where !character.isASCII {
        throw EDFEncodingError.invalidCharacter(field: field, character, value: value)
    }
}


extension String {
    var isASCII: Bool {
        allSatisfy { character in
            character.isASCII
        }
    }
}
