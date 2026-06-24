<!--

This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT

-->

# SpeziNetworking


A collection of networking-related infrastructure to support Spezi applications.

## Overview

SpeziNetworking provides easy to use infrastructure in networking applications.

### ByteCoding

The `ByteCoding` package provides the necessary infrastructure to make encoding and decoding of a type to or from its
respective binary representation easy to use.

|                                                         Type                                                          | Description                                                           |
|:---------------------------------------------------------------------------------------------------------------------:|-----------------------------------------------------------------------|
|   [`ByteCodable`](../ByteCoding/ByteCoding.docc/ByteCoding.md)   | A type that is encodable to and decodable from a byte representation. |
| [`ByteEncodable`](../ByteCoding/ByteCoding.docc/ByteCoding.md) | A type that is decodable to a byte representation.                    |
| [`ByteDecodable`](../ByteCoding/ByteCoding.docc/ByteCoding.md) | A type that is decodable from a byte representation.                  |

### SpeziNumerics

Implementation of numeric types that are not supported out of the box in the standard library or are only found in networking protocols.

|                                                                  Type                                                                  | Description                                                  |
|:--------------------------------------------------------------------------------------------------------------------------------------:|--------------------------------------------------------------|
|           [`MedFloat16`](../SpeziNumerics/SpeziNumerics.docc/SpeziNumerics.md)           | Medical 16-bit float using base 10                           |
|           [`MedFloat32`](../SpeziNumerics/SpeziNumerics.docc/SpeziNumerics.md)           | Medical 32-bit float using base 10                           |
| [Int24/UInt24 Support](../SpeziNumerics/SpeziNumerics.docc/SpeziNumerics.md) | Support reading and writing Int24 and UInt24 with ByteBuffer |

## Setup

Add the Spezi monorepo package to your app and select the `ByteCoding` and `SpeziNumerics` products.

In Xcode, select **File > Add Package Dependencies...**, enter:

```text
https://github.com/SchmiedmayerLab/Spezi.git
```

Choose **Up to Next Minor Version** and enter the latest tagged `0.x` release, for example `0.1.0`.

If you manage dependencies in a `Package.swift`, add the package dependency:

```swift
.package(url: "https://github.com/SchmiedmayerLab/Spezi.git", .upToNextMinor(from: "0.1.0"))
```

Then add the product dependency to the target that needs it:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "ByteCoding", package: "Spezi"),
        .product(name: "SpeziNumerics", package: "Spezi")
    ]
)
```

## License

This target is licensed under the MIT License. The local [LICENSES](LICENSES) directory records license information imported from the original upstream repository. See the monorepo [LICENSES](../../LICENSES) directory for license information covering current changes in this repository.


## Contributors

The local [CONTRIBUTORS.md](CONTRIBUTORS.md) file records contributors from the original upstream repository. See the monorepo [CONTRIBUTORS.md](../../CONTRIBUTORS.md) file for contributors to current changes in this repository.
