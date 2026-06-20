<!--
                  
This source file is part of the ThreadLocal open source project

SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# ThreadLocal

[![Build and Test](https://github.com/StanfordBDHG/ThreadLocal/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordBDHG/ThreadLocal/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/StanfordBDHG/ThreadLocal/branch/main/graph/badge.svg?token=X7BQYSUKOH)](https://codecov.io/gh/StanfordBDHG/ThreadLocal)
<!-- [![DOI](https://zenodo.org/badge/573230182.svg)](https://zenodo.org/badge/latestdoi/573230182) -->
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordBDHG%2FThreadLocal%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordBDHG/ThreadLocal)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordBDHG%2FThreadLocal%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordBDHG/ThreadLocal)

Thread-local variables for Swift.


## Overview

Use the ``ThreadLocal()`` macro to define a thread-local static variable:
```swift
extension SomeType {
    @ThreadLocal
    private static var counter: Int = 0
}
```
Each thread will have its own version of the variable.
On each thread, the variable is initially initialized to its default value (0 in the example above).
When the thread is destroyed, the variable's lifetime is ended.

You can use non-trivial types with thread-local variables, and can provide a custom deallocator if needed (see ``ThreadLocal(deallocator:)``).

See [the documentation](https://swiftpackageindex.com/StanfordBDHG/ThreadLocal) for more info.


## Installation

The project can be added to your Xcode project or Swift Package using the [Swift Package Manager](https://github.com/apple/swift-package-manager).

**Xcode:** For an Xcode project, follow the instructions on [adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

**Swift Package:** You can follow the [Swift Package Manager documentation about defining dependencies](https://github.com/apple/swift-package-manager/blob/main/Documentation/Usage.md#defining-dependencies) to add this project as a dependency to your Swift Package.


## License
This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordBDHG/ThreadLocal/tree/main/LICENSES) for more information.


## Contributors
This project is developed as part of the Stanford Mussallem Center for Biodesign at Stanford University.
See [CONTRIBUTORS.md](https://github.com/lukaskollmer/ThreadLocal/tree/main/CONTRIBUTORS.md) for a full list of all ThreadLocal contributors.

![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-light.png#gh-light-mode-only)
![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-dark.png#gh-dark-mode-only)
