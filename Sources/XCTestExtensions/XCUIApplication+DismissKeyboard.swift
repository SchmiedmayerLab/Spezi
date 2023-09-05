//
// This source file is part of the Stanford XCTestExtensions open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest

/// Replicates Apples [SubmitLabel](https://developer.apple.com/documentation/swiftui/submitlabel).
///
/// This is a empirical list of XCUI `identifiers` of keyboards with the respective SubmitLabel. To do so use the `debugDescription` of the `keyboard` XCUIElement.
/// - Note: The `continue` button is the only button that doesn't have an identifier, just the `label` shown to the user. Consequentially, this button is language dependent.
private enum SubmitLabels: String, CaseIterable {
    case `continue` = "continue"
    case done = "Done"
    case go = "Go" // swiftlint:disable:this identifier_name
    case join = "Join:"
    case next = "Next:"
    case `return` = "Return"
    case route = "Route"
    case search = "Search"
    case send = "Send"
}

extension XCUIApplication {
    /// Dismisses the keyboard if it is currently displayed.
    public func dismissKeyboard() {
        let keyboard = keyboards.firstMatch

        guard keyboard.exists else {
            return
        }

        for label in SubmitLabels.allCases {
            guard keyboard.buttons[label.rawValue].exists && keyboard.buttons[label.rawValue].isHittable else {
                continue
            }

            keyboard.buttons[label.rawValue].tap()
            return
        }

        // If we reach here, we weren't successful with our built list of submit labels.
        // Falling back to doing it by heuristic.
        if let returnKey = keyboard.buttons.allElementsBoundByIndex.last,
           returnKey.isHittable {
            // the "return" key is usually the last button on the keyboard.
            returnKey.tap()
        }
    }
}
