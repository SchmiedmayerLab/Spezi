<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# SpeziNetworking

[![Build and Test](https://github.com/StanfordSpezi/SpeziNetworking/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordSpezi/SpeziNetworking/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/StanfordSpezi/SpeziNetworking/graph/badge.svg?token=emNLUokqWO)](https://codecov.io/gh/StanfordSpezi/SpeziNetworking)
[![DOI](https://zenodo.org/badge/811321013.svg)](https://zenodo.org/doi/10.5281/zenodo.11508061)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziNetworking%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordSpezi/SpeziNetworking)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziNetworking%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordSpezi/SpeziNetworking)

A collection of networking-related infrastructure to support Spezi applications.

## Overview

SpeziNetworking provides easy to use infrastructure in networking applications.

### ByteCoding

The `ByteCoding` package provides the necessary infrastructure to make encoding and decoding of a type to or from its
respective binary representation easy to use.

|                                                         Type                                                          | Description                                                           |
|:---------------------------------------------------------------------------------------------------------------------:|-----------------------------------------------------------------------|
|   [`ByteCodable`](https://swiftpackageindex.com/stanfordspezi/spezinetworking/documentation/bytecoding/bytecodable)   | A type that is encodable to and decodable from a byte representation. |
| [`ByteEncodable`](https://swiftpackageindex.com/stanfordspezi/spezinetworking/documentation/bytecoding/byteencodable) | A type that is decodable to a byte representation.                    |
| [`ByteDecodable`](https://swiftpackageindex.com/stanfordspezi/spezinetworking/documentation/bytecoding/bytedecodable) | A type that is decodable from a byte representation.                  |

### SpeziNumerics

Implementation of numeric types that are not supported out of the box in the standard library or are only found in networking protocols.

|                                                                  Type                                                                  | Description                                                  |
|:--------------------------------------------------------------------------------------------------------------------------------------:|--------------------------------------------------------------|
|           [`MedFloat16`](https://swiftpackageindex.com/stanfordspezi/spezinetworking/documentation/spezinumerics/medfloat16)           | Medical 16-bit float using base 10                           |
|           [`MedFloat32`](https://swiftpackageindex.com/stanfordspezi/spezinetworking/documentation/spezinumerics/medfloat32)           | Medical 32-bit float using base 10                           |
| [Int24/UInt24 Support](https://swiftpackageindex.com/stanfordspezi/spezinetworking/documentation/spezinumerics#24-bit-integer-support) | Support reading and writing Int24 and UInt24 with ByteBuffer |

## Setup

You need to add the SpeziNetworking Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

## License
This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/SpeziNetworking/tree/main/LICENSES) for more information.


## Contributors
This project is developed as part of the Stanford Byers Center for Biodesign at Stanford University.
See [CONTRIBUTORS.md](https://github.com/StanfordSpezi/SpeziNetworking/tree/main/CONTRIBUTORS.md) for a full list of all TemplatePackage contributors.

![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/Footer.png#gh-light-mode-only)
![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/Footer~dark.png#gh-dark-mode-only)
