//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OSLog
import XCTest


/// An internal flag that is used to test the flaky simulator text entry behaviour in the iOS simulator.
///
/// Do not use this flag outside of the UI tests in the ``XCTestExtensions`` target!
var simulateFlakySimulatorTextEntry = false


extension XCUIElement {
    /// Get the current value so we can assert if the text entry was correct.
    private var currentValue: String {
        if value as? String == placeholderValue {
            // If the value is the placeholderValue we assume that the text field has no value entered.
            return ""
        } else {
            return value as? String ?? ""
        }
    }
    
    
    /// Delete a fixed number of characters in a text field or secure text field.
    /// - Parameter count: The number of characters that should be deleted.
    /// - Parameter checkIfTextWasDeletedCorrectly: Check if the text was deleted correctly.
    /// - Throws: Throws an `XCTestError` of the number of characters could not be deleted.
    ///
    /// Unfortunately, the iOS simulator sometimes has flaky behavior when entering text in a simulator with low computation resources.
    /// The method provides the `checkIfTextWasDeletedCorrectly` parameter that is set to true by default to check if the characters were deleted correctly.
    /// If your text entry does fail to do so, e.g., a deletion in a secure text field, set the `checkIfTextWasDeletedCorrectly` parameter to `false`.
    public func delete(count: Int, checkIfTextWasDeletedCorrectly: Bool = true) throws {
        try delete(count: count, checkIfTextWasDeletedCorrectly: checkIfTextWasDeletedCorrectly, recursiveDepth: 0)
    }
    
    /// Type a text in a text field or secure text field.
    /// - Parameter newValue: The text that should be typed.
    /// - Parameter checkIfTextWasEnteredCorrectly: Check if the text was entered correctly.
    /// - Throws: Throws an `XCTestError` of the text could not be entered in the text field.
    ///
    /// Unfortunately, the iOS simulator sometimes has flaky behavior when entering text in a simulator with low computation resources.
    /// The method provides the `checkIfTextWasEnteredCorrectly` parameter that is set to true by default to check if the characters were entered correctly.
    /// If your text entry does fail to do so, e.g., an entry in a secure text field, set the `checkIfTextWasEnteredCorrectly` parameter to `false`.
    public func enter(value newValue: String, checkIfTextWasEnteredCorrectly: Bool = true) throws {
        try enter(value: newValue, checkIfTextWasEnteredCorrectly: checkIfTextWasEnteredCorrectly, recursiveDepth: 0)
    }
    
    
    private func delete( // swiftlint:disable:this function_default_parameter_at_end
        count: Int,
        checkIfTextWasDeletedCorrectly: Bool = true,
        // We put this paramter at the end of the function to mimic the public interface with an internal extension.
        recursiveDepth: Int
    ) throws {
        guard recursiveDepth <= 2 else {
            os_log("Could not successfully delete \(count) characters in the textfield \(self.debugDescription)")
            throw XCTestError(.failureWhileWaiting)
        }
        
        // Get the current value so we can assert if the text deleted was correct.
        let currentValueCount = currentValue.count
        
        // Select the textfield
        selectField()
        
        // Delete the text
        if simulateFlakySimulatorTextEntry && recursiveDepth < 2 {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count - 1))
        } else {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count))
        }
        
        // Check of the text was deleted correctly:
        if checkIfTextWasDeletedCorrectly {
            let countAfterDeletion = currentValue.count
            
            if max(currentValueCount - count, 0) < countAfterDeletion {
                try delete(
                    count: countAfterDeletion - (currentValueCount - count),
                    checkIfTextWasDeletedCorrectly: true,
                    recursiveDepth: recursiveDepth + 1
                )
            }
        }
    }
    
    private func enter( // swiftlint:disable:this function_default_parameter_at_end
        value textToEnter: String,
        checkIfTextWasEnteredCorrectly: Bool = true,
        // We put this paramter at the end of the function to mimic the public interface with an internal extension.
        recursiveDepth: Int
    ) throws {
        guard recursiveDepth <= 2 else {
            os_log("Could not successfully verify entering \"\(textToEnter)\" in the textfield \(self.debugDescription)")
            throw XCTestError(.failureWhileWaiting)
        }
        
        // Get the current value so we can assert if the text entry was correct.
        let previousValue = currentValue
        
        // Select the textfield
        selectField()
        
        // Enter the value
        if simulateFlakySimulatorTextEntry && recursiveDepth < 2 {
            typeText(String(textToEnter.dropLast(1)))
        } else {
            typeText(textToEnter)
        }
        
        // Check of the text was entered correctly:
        if checkIfTextWasEnteredCorrectly {
            let valueAfterTextEntry = currentValue
            
            if self.elementType == .secureTextField {
                if previousValue.isEmpty && textToEnter.count != valueAfterTextEntry.count {
                    // We delete the text twice to ensure that we have an empty text field even if the textfield might go byeond the current scope
                    try delete(count: valueAfterTextEntry.count, checkIfTextWasDeletedCorrectly: false)
                    try delete(count: valueAfterTextEntry.count, checkIfTextWasDeletedCorrectly: false)
                    
                    try enter(
                        value: previousValue + textToEnter,
                        checkIfTextWasEnteredCorrectly: true,
                        recursiveDepth: recursiveDepth + 1
                    )
                } else if previousValue.count + textToEnter.count != valueAfterTextEntry.count {
                    os_log(
                        """
                        The text entered in the secure text field doesn't seem to match the desired length.
                        We can not re-enter the value as we don't have an insight into the value that was present in the secure text field before.
                        """
                    )
                    throw XCTestError(.failureWhileWaiting)
                }
            } else {
                if previousValue + textToEnter != valueAfterTextEntry {
                    // We delete the text twice to ensure that we have an empty text field even if the textfield might go byeond the current scope
                    try delete(count: valueAfterTextEntry.count, checkIfTextWasDeletedCorrectly: false)
                    try delete(count: valueAfterTextEntry.count, checkIfTextWasDeletedCorrectly: false)
                    
                    try enter(
                        value: previousValue + textToEnter,
                        checkIfTextWasEnteredCorrectly: true,
                        recursiveDepth: recursiveDepth + 1
                    )
                }
            }
        }
    }
    
    
    private func selectField() {
        // Select the textfield
        var offset = 0.99
        repeat {
            coordinate(withNormalizedOffset: CGVector(dx: offset, dy: 0.5)).tap()
            offset -= 0.05
        } while !XCUIApplication().keyboards.firstMatch.waitForExistence(timeout: 2.0) && offset > 0
    }
}
