# ``XCTestExtensions``

<!--
                  
This source file is part of the XCTestExtensions open source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

XCTestExtensions is a collection of extensions for commonly used functionality in UI tests using XCTest.

You can use XCTestExtensions in your UI tests.
The framework has the following functionalities:


### Delete & Launch Application

Delete and launch the application. Use this function to completely reset the application, e.g., for system permission screens and alerts.
```swift
let app = XCUIApplication()
app.deleteAndLaunch(withSpringboardAppName: "TestApp")
```


### Disable Password Autofill

The iOS Simulator has enabled password autofill by default, which can interfere with text entry in password fields in UI tests. The `XCTestCase` extension provides the `disablePasswordAutofill` to navigate to the settings app and disable password autofill.
```swift
class TestAppUITests: XCTestCase {
    func testDeleteAndLaunch() throws {
        disablePasswordAutofill()
        
        // ...
    }
}
```


### Text Entry

Allows a simple extension on `XCUIElement` to delete and type text in a text field or secure text field.
```swift
let app = XCUIApplication()

let textField = app.textFields["TextField"]
textField.enter(value: "Example Text")
textField.delete(count: 5)

let secureTextField = app.secureTextFields["SecureField"]
secureTextField.enter(value: "Secure Text")
secureTextField.delete(count: 5)
```
