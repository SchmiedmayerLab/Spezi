<!--
                  
This source file is part of the Stanford Spezi open source project

SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# SpeziStudy

Reusable study definitions and infrastructure for the Spezi ecosystem

[![CI](https://github.com/StanfordSpezi/SpeziStudy/actions/workflows/ci.yml/badge.svg)](https://github.com/StanfordSpezi/SpeziStudy/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/StanfordSpezi/SpeziStudy/branch/main/graph/badge.svg?token=X7BQYSUKOH)](https://codecov.io/gh/StanfordSpezi/SpeziStudy)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziStudy%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordSpezi/SpeziStudy)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziStudy%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordSpezi/SpeziStudy)


## Overview

The SpeziStudy package consists of the following modules:
- [`SpeziStudyDefinition`](https://swiftpackageindex.com/stanfordspezi/spezistudy/documentation/spezistudydefinition): implements the [`StudyDefinition`](https://swiftpackageindex.com/stanfordspezi/spezistudy/documentation/spezistudydefinition/studydefinition) type, used for defining reusable studies that can be used with the Spezi ecosystem.
- [`SpeziStudy`](https://swiftpackageindex.com/stanfordspezi/spezistudy/documentation/spezistudy): implements study-enrollment and participation infrastructure, such as e.g. the [`StudyManager`](https://swiftpackageindex.com/stanfordspezi/spezistudy/documentation/spezistudy/studymanager).

You enable and configure the ``StudyManager`` by including it in your app's `SpeziAppDelegate`:
```swift
class ExampleAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: ExampleStandard()) {
            StudyManager()
        }
    }
}
```

For more information, please refer to the [API documentation](https://swiftpackageindex.com/StanfordSpezi/SpeziStudy/documentation).


## The Spezi Template Application

The [Spezi Template Application](https://github.com/StanfordSpezi/SpeziTemplateApplication) provides a great starting point and example using the [`SpeziStudy`](https://swiftpackageindex.com/stanfordspezi/spezistudy/documentation/spezistudy) module.


## Contributing

Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/StanfordSpezi/.github/blob/main/CONTRIBUTING.md) and the [contributor covenant code of conduct](https://github.com/StanfordSpezi/.github/blob/main/CODE_OF_CONDUCT.md) first.


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/SpeziStudy/tree/main/LICENSES) for more information.

![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterLight.png#gh-light-mode-only)
![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterDark.png#gh-dark-mode-only)
