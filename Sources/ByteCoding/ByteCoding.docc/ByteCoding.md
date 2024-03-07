# ``ByteCoding``

<!--
#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#
-->

Encode and decode types from and to their byte representation.

## Overview

This library provides a standardized approach of encoding and decoding types from and to their byte representation.

## Topics

### Coding

- ``ByteCodable``
- ``ByteEncodable``
- ``ByteDecodable``

### 24 Bit Integer Support

- ``NIOCore/ByteBuffer/getUInt24(at:endianness:)``
- ``NIOCore/ByteBuffer/readUInt24(endianness:)``
- ``NIOCore/ByteBuffer/setUInt24(_:at:endianness:)``
- ``NIOCore/ByteBuffer/writeUInt24(_:endianness:)``
- ``NIOCore/ByteBuffer/getInt24(at:endianness:)``
- ``NIOCore/ByteBuffer/readInt24(endianness:)``
- ``NIOCore/ByteBuffer/setInt24(_:at:endianness:)``
- ``NIOCore/ByteBuffer/writeInt24(_:endianness:)``
