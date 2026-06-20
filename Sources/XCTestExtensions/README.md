<!--
                  
This source file is part of the Stanford XCTestExtensions open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# XCTestExtensions

[![Build and Test](https://github.com/StanfordBDHG/XCTestExtensions/actions/workflows/ci.yml/badge.svg)](https://github.com/StanfordBDHG/XCTestExtensions/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/StanfordBDHG/XCTestExtensions/branch/main/graph/badge.svg?token=dF75iJxl45)](https://codecov.io/gh/StanfordBDHG/XCTestExtensions)
[![DOI](https://zenodo.org/badge/597215549.svg)](https://zenodo.org/badge/latestdoi/597215549)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordBDHG%2FXCTestExtensions%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordBDHG/XCTestExtensions)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordBDHG%2FXCTestExtensions%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordBDHG/XCTestExtensions)

This Swift Package provides convenient extension points to write tests using XCTest.

`XCTestExtensions` is a collection of extensions for commonly used functionality in UI tests using XCTest. You can learn more about [`XCTestExtensions` in the API documentation](https://swiftpackageindex.com/StanfordBDHG/XCTestExtensions/documentation/xctestextensions).
It includes the functionality to 
- delete & launch an application to reset the application
- disable password autofill on an iOS simulator to avoid challenges with the text entry in secure text fields
- enable a simple text entry in plain and secure text fields

The `XCTestApp` target enables writing test-based apps that can be verified in a UI test. You can learn more about [`XCTestApp` in the API documentation](https://swiftpackageindex.com/StanfordBDHG/XCTestExtensions/documentation/xctestapp).

## Installation

You need to add the XCTestExtensions Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordBDHG/XCTestExtensions/tree/main/LICENSES) for more information.


## Contributors

This project is developed as part of the Stanford Byers Center for Biodesign at Stanford University.
See [CONTRIBUTORS.md](https://github.com/StanfordBDHG/XCTestExtensions/tree/main/CONTRIBUTORS.md) for a full list of all XCTestExtensions contributors.

![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-light.png#gh-light-mode-only)
![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-dark.png#gh-dark-mode-only)
