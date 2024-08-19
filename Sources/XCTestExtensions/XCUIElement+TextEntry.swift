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


/// Modify the behavior of text entry and text deletion.
public struct TextInputOptions: OptionSet, Sendable {
    /// Disable the automatic dismiss of the keyboard at the end of text entry.
    ///
    /// By default the keyboard will be automatically dismissed after text entry. If you want to disable this behavior, e.g., entering input into the text field
    /// in multiple steps, you can disable that behavior by specifying this option.
    public static let disableKeyboardDismiss = TextInputOptions(rawValue: 1 << 0)
    // on visionOS the keyboard app running state is always foreground and the keyboards query doesn't do anything.

    /// Place the cursor on the rightmost position in the text field.
    ///
    /// By default, the the textfield is selected by performing standard [`tap()`](https://developer.apple.com/documentation/xctest/xcuielement/1618666-tap)
    /// on the text field which puts the cursor in the middle of the text field.
    /// This might be an issue when working with text fields that have existing input, as the cursor will be place in the middle of the text.
    /// When using this option, the text field is selected by continuously tapping from the rightmost edge of the text field until the keyboard exists.
    ///
    /// - Note: This method doesn't work on visionOS or macOS. For macOS you can manually call [`coordinate(withNormalizedOffset:)`](https://developer.apple.com/documentation/xctest/xcuielement/1500960-coordinate)
    ///  to tap on a fitting coordinate and then use the ``skipTextFieldSelection`` option. For visionOS `coordinate(withNormalizedOffset:)` doesn't work. Aim to not
    ///  test with longer text entry on visionOS.
    @available(visionOS, unavailable, message: "Tapping from the far right is unsupported on visionOS")
    @available(macOS, unavailable, message: "Tapping from the far right is unsupported on macOS")
    public static let tapFromRight = TextInputOptions(rawValue: 1 << 1)
    /// Do not verify if text was enter correctly.
    ///
    /// Unfortunately, the iOS simulator sometimes has flaky behavior when entering text in a simulator with low computation resources.
    /// By default, it will be verified if the characteristic were enter/deleted correctly.
    /// Use this option to disable this behavior.
    public static let skipTextInputValidation = TextInputOptions(rawValue: 1 << 2)
    /// Do not automatically select the text field before typing.
    ///
    /// By default the text field is automatically selected before typing text. Use this option to disable this behavior, if you
    /// know the keyboard to already be present.
    public static let skipTextFieldSelection = TextInputOptions(rawValue: 1 << 3)

    /// Same option as ``tapFromRight``, but accessible for us internally without compiler conditions.
    fileprivate static let _tapFromRight = TextInputOptions(rawValue: 1 << 1)

    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}


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
    ///
    /// ```swift
    /// try app.textFields["enter first name"].delete(4)
    /// ```
    ///
    /// - Parameters:
    ///   - count: The number of characters that should be deleted.
    ///   - options: Control additional behavior how text deletion should be performed.
    /// - Throws: Throws an `XCTestError`, if the number of characters could not be deleted.
    public func delete(count: Int, options: TextInputOptions = []) throws {
        if !options.contains(.skipTextFieldSelection) {
            selectField(options: options)
        }

        try performDelete(count: count, options: options, recursiveDepth: 0)

        if !options.contains(.disableKeyboardDismiss) {
            XCUIApplication().dismissKeyboard()
        }
    }
    
    /// Type a text in a text field or secure text field.
    ///
    /// ```swift
    /// try app.textFields["enter first name"].enter("Hello World")
    /// ```
    ///
    /// - Parameters:
    ///   - newValue: The text that should be typed.
    ///   - options: Control additional behavior how text entry should be performed.
    /// - Throws: Throws an `XCTestError`, if the text could not be entered in the text field.
    public func enter(value newValue: String, options: TextInputOptions = []) throws {
        if !options.contains(.skipTextFieldSelection) {
            selectField(options: options)
        }

        try performEnter(value: newValue, options: options, recursiveDepth: 0)

        if !options.contains(.disableKeyboardDismiss) {
            XCUIApplication().dismissKeyboard()
        }
    }


    private func performDelete(count: Int, options: TextInputOptions, recursiveDepth: Int) throws {
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
        if !options.contains(.skipTextInputValidation) {
            let countAfterDeletion = currentValue.count

            if max(currentValueCount - count, 0) < countAfterDeletion {
                tap() // cursor might not be placed at the rightmost position of the text field
                try performDelete(count: countAfterDeletion - ( currentValueCount - count), options: options, recursiveDepth: recursiveDepth + 1)
            }
        }
    }

    private func performEnter(value textToEnter: String, options: TextInputOptions, recursiveDepth: Int) throws {
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
        if !options.contains(.skipTextInputValidation) {
            let valueAfterTextEntry = currentValue
            
            if self.elementType == .secureTextField {
                if previousValue.isEmpty && textToEnter.count != valueAfterTextEntry.count {
                    try performDelete(count: valueAfterTextEntry.count, options: [], recursiveDepth: 0)
                    tap() // cursor might not be placed at the rightmost position of the text field
                    try performDelete(count: valueAfterTextEntry.count, options: [], recursiveDepth: 0)

                    try performEnter(value: previousValue + textToEnter, options: options, recursiveDepth: recursiveDepth + 1)
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
                    try performDelete(count: valueAfterTextEntry.count, options: [], recursiveDepth: 0)
                    tap() // cursor might not be placed at the rightmost position of the text field
                    try performDelete(count: valueAfterTextEntry.count, options: [], recursiveDepth: 0)

                    try performEnter(value: previousValue + textToEnter, options: options, recursiveDepth: recursiveDepth + 1)
                }
            }
        }
    }
    

    /// Taps the text field on a XCUIElement that is a text field or secure text field.
    ///
    /// - Note: This will not necessarily bring up the keyboard in the simulator. Don't expect buttons to show there.
    ///     If the user interacted with the Simulator (e.g. Mouse clicks) the keyboard won't show as the simulator expects input via the Mac Keyboard.
    ///     This is controlled via I/O -> Keyboard -> Connect Hardware Keyboard / Toggle Software Keyboard
    func selectField(options: TextInputOptions = []) {
        let app = XCUIApplication()

        if options.contains(._tapFromRight) {
            // Select the text field, see https://stackoverflow.com/questions/38523125/place-cursor-at-the-end-of-uitextview-under-uitest

            XCTAssertFalse(app.keyboards.firstMatch.exists, "Keyboard must not exist when selecting text field from the right.")

            var offset = 0.99
            repeat {
                coordinate(withNormalizedOffset: CGVector(dx: offset, dy: 0.5)).tap()
                offset -= 0.05
            } while offset >= 0 && !app.keyboards.firstMatch.waitForExistence(timeout: 2.0)

            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2.0), "Keyboard does not exist.")
        } else {
            tap()

            #if os(visionOS)
            XCTAssertTrue(app.visionOSKeyboard.wait(for: .runningForeground, timeout: 2.0))
            #elseif !os(macOS) && !targetEnvironment(macCatalyst)
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2.0))
            #endif
        }

        // With latest simulator releases it seems like the "swift to type" tutorial isn't popping up anymore.
        // For more information see https://developer.apple.com/forums/thread/650826.
    }
}
