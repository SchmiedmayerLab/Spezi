//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OSLog
import XCTest


/// An internal flag that is used to test the flaky simulator text entry behavior in the iOS simulator.
///
/// Do not use this flag outside of the UI tests in the ``XCTestExtensions`` target!
@MainActor var simulateFlakySimulatorTextEntry = false


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
    /// - Parameter dismissKeyboard: Press the return key after deleting the text.
    /// - Throws: Throws an `XCTestError` of the number of characters could not be deleted.
    ///  
    /// Unfortunately, the iOS simulator sometimes has flaky behavior when entering text in a simulator with low computation resources.
    /// The method provides the `checkIfTextWasDeletedCorrectly` parameter that is set to true by default to check if the characters were deleted correctly.
    /// If your text entry does fail to do so, e.g., a deletion in a secure text field, set the `checkIfTextWasDeletedCorrectly` parameter to `false`.
    public func delete(
        count: Int,
        checkIfTextWasDeletedCorrectly: Bool = true,
        dismissKeyboard: Bool = true
    ) throws {
        // Select the textfield
        selectField(dismissKeyboard: dismissKeyboard)

        try performDelete(count: count, checkIfTextWasDeletedCorrectly: checkIfTextWasDeletedCorrectly, recursiveDepth: 0)

        if dismissKeyboard {
            XCUIApplication().dismissKeyboard()
        }
    }
    
    /// Type a text in a text field or secure text field.
    /// - Parameter newValue: The text that should be typed.
    /// - Parameter checkIfTextWasEnteredCorrectly: Check if the text was entered correctly.
    /// - Parameter dismissKeyboard: Press the return key after entering the text.
    /// - Throws: Throws an `XCTestError` of the text could not be entered in the text field.
    ///
    /// Unfortunately, the iOS simulator sometimes has flaky behavior when entering text in a simulator with low computation resources.
    /// The method provides the `checkIfTextWasEnteredCorrectly` parameter that is set to true by default to check if the characters were entered correctly.
    /// If your text entry does fail to do so, e.g., an entry in a secure text field, set the `checkIfTextWasEnteredCorrectly` parameter to `false`.
    public func enter(
        value newValue: String,
        checkIfTextWasEnteredCorrectly: Bool = true,
        dismissKeyboard: Bool = true
    ) throws {
        // Select the textfield
        selectField(dismissKeyboard: dismissKeyboard)

        try performEnter(
            value: newValue,
            checkIfTextWasEnteredCorrectly: checkIfTextWasEnteredCorrectly,
            dismissKeyboard: dismissKeyboard,
            recursiveDepth: 0
        )

        if dismissKeyboard {
            XCUIApplication().dismissKeyboard()
        }
    }


    private func performDelete(
        count: Int,
        checkIfTextWasDeletedCorrectly: Bool,
        recursiveDepth: Int
    ) throws {
        guard recursiveDepth <= 2 else {
            os_log("Could not successfully delete \(count) characters in the textfield \(self.debugDescription)")
            throw XCTestError(.failureWhileWaiting)
        }

        // Get the current value so we can assert if the text deleted was correct.
        let currentValueCount = currentValue.count

        // Delete the text
        if simulateFlakySimulatorTextEntry && recursiveDepth < 2 {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: max(0, count - 1)))
        } else {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count))
        }

        // Check of the text was deleted correctly:
        if checkIfTextWasDeletedCorrectly {
            let countAfterDeletion = currentValue.count

            if max(currentValueCount - count, 0) < countAfterDeletion {
                try performDelete(
                    count: countAfterDeletion - ( currentValueCount - count),
                    checkIfTextWasDeletedCorrectly: true,
                    recursiveDepth: recursiveDepth + 1
                )
            }
        }
    }

    private func performEnter(
        value textToEnter: String,
        checkIfTextWasEnteredCorrectly: Bool,
        dismissKeyboard: Bool,
        recursiveDepth: Int
    ) throws {
        guard recursiveDepth <= 2 else {
            os_log("Could not successfully verify entering \"\(textToEnter)\" in the textfield \(self.debugDescription)")
            throw XCTestError(.failureWhileWaiting)
        }
        
        // Get the current value so we can assert if the text entry was correct.
        let previousValue = currentValue

        // Enter the value
        if simulateFlakySimulatorTextEntry && recursiveDepth < 2 {
            typeText(String(textToEnter.dropLast(1)))
        } else {
            typeText(textToEnter)
        }
        
        // Check if the text was entered correctly
        if checkIfTextWasEnteredCorrectly {
            let valueAfterTextEntry = currentValue
            
            if self.elementType == .secureTextField {
                if previousValue.isEmpty && textToEnter.count != valueAfterTextEntry.count {
                    // We delete the text twice to ensure that we have an empty text field even if the textfield might go beyond the current scope
                    try performDelete(count: valueAfterTextEntry.count, checkIfTextWasDeletedCorrectly: false, recursiveDepth: 0)
                    XCUIApplication().dismissKeyboard()
                    try delete(count: valueAfterTextEntry.count, checkIfTextWasDeletedCorrectly: false, dismissKeyboard: false)

                    try performEnter(
                        value: previousValue + textToEnter,
                        checkIfTextWasEnteredCorrectly: true,
                        dismissKeyboard: dismissKeyboard,
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
                    // We delete the text twice to ensure that we have an empty text field even if the textfield might go beyond the current scope
                    try performDelete(count: valueAfterTextEntry.count, checkIfTextWasDeletedCorrectly: false, recursiveDepth: 0)
                    XCUIApplication().dismissKeyboard()
                    try delete(count: valueAfterTextEntry.count, checkIfTextWasDeletedCorrectly: false, dismissKeyboard: false)

                    try performEnter(
                        value: previousValue + textToEnter,
                        checkIfTextWasEnteredCorrectly: true,
                        dismissKeyboard: dismissKeyboard,
                        recursiveDepth: recursiveDepth + 1
                    )
                }
            }
        }
    }
    

    /// Taps the text field on a XCUIElement that is a text field or secure text field.
    ///
    /// - Note: This will not necessarily bring up the keyboard in the simulator. Don't expect buttons to show there.
    ///     If the user interacted with the Simulator (e.g. Mouse clicks) the keyboard won't show as the simulator expects input via the Mac Keyboard.
    ///     This is controlled via I/O -> Keyboard -> Connect Hardware Keyboard / Toggle Software Keyboard
    func selectField(dismissKeyboard: Bool) {
        let app = XCUIApplication()

        // With visionOS we can't detect if the keyboard is currently shown. Interacting with a keyboard that is not shown will fail though.
        // So we have to build around the assumption that the keyboard is not shown when we select a text field.
        #if !os(visionOS)
        // Press the return button if the keyboard is currently active.
        if dismissKeyboard {
            app.dismissKeyboard()
        }
        #endif

        #if os(visionOS)
        tap()
        _ = app.visionOSKeyboard.waitForExistence(timeout: 2.0) // this will always succeed
        #elseif os(macOS) || targetEnvironment(macCatalyst)
        // this should hit the keyboard most likely. The `.keyboard` query doesn't exist on macOS.
        coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        #else
        let keyboard = app.keyboards.firstMatch

        // Select the text field, see https://stackoverflow.com/questions/38523125/place-cursor-at-the-end-of-uitextview-under-uitest
        var offset = 0.99
        repeat {
            coordinate(withNormalizedOffset: CGVector(dx: offset, dy: 0.5)).tap()
            offset -= 0.05
        } while !keyboard.waitForExistence(timeout: 2.0) && offset > 0
        #endif

        // With latest simulator releases it seems like the "swift to type" tutorial isn't popping up anymore.
        // For more information see https://developer.apple.com/forums/thread/650826.
    }
}
