//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// The location of an EEG electrode.
public enum EEGLocation: String {
    /// Pg1
    case pg1 = "Pg1"
    /// Nz
    case nz = "Nz" // swiftlint:disable:this identifier_name
    /// Pg2
    case pg2 = "Pg2"

    /// Fp1
    case fp1 = "Fp1"
    /// Fpz
    case fpz = "Fpz"
    /// Fp2
    case fp2 = "Fp2"

    /// AF7
    case af7 = "AF7"
    /// AF3
    case af3 = "AF3"
    /// AFz
    case afz = "AFz"
    /// AF4
    case af4 = "AF4"
    /// AF8
    case af8 = "AF8"
    /// F9
    case f9 = "F9" // swiftlint:disable:this identifier_name
    /// F7
    case f7 = "F7" // swiftlint:disable:this identifier_name
    /// F5
    case f5 = "F5" // swiftlint:disable:this identifier_name
    /// F3
    case f3 = "F3" // swiftlint:disable:this identifier_name
    /// F1
    case f1 = "F1" // swiftlint:disable:this identifier_name
    /// Fz
    case fz = "Fz" // swiftlint:disable:this identifier_name
    /// F2
    case f2 = "F2" // swiftlint:disable:this identifier_name
    /// F4
    case f4 = "F4" // swiftlint:disable:this identifier_name
    /// F6
    case f6 = "F6" // swiftlint:disable:this identifier_name
    /// F8
    case f8 = "F8" // swiftlint:disable:this identifier_name
    /// F10
    case f10 = "F10"

    /// FT9
    case ft9 = "FT9"
    /// FT7
    case ft7 = "FT7"
    /// FC5
    case fc5 = "FC5"
    /// FC3
    case fc3 = "FC3"
    /// FC1
    case fc1 = "FC1"
    /// FCz
    case fcz = "FCz"
    /// FC2
    case fc2 = "FC2"
    /// FC4
    case fc4 = "FC4"
    /// FC6
    case fc6 = "FC6"
    /// FT8
    case ft8 = "FT8"
    /// FT10
    case ft10 = "FT10"
    /// A1
    case a1 = "A1" // swiftlint:disable:this identifier_name

    /// T9
    case t9 = "T9" // swiftlint:disable:this identifier_name
    /// T7
    case t7 = "T7" // swiftlint:disable:this identifier_name
    /// C5
    case c5 = "C5" // swiftlint:disable:this identifier_name
    /// C3
    case c3 = "C3" // swiftlint:disable:this identifier_name
    /// C1
    case c1 = "C1" // swiftlint:disable:this identifier_name
    /// Cz
    case cz = "Cz" // swiftlint:disable:this identifier_name
    /// C2
    case c2 = "C2" // swiftlint:disable:this identifier_name
    /// C4
    case c4 = "C4" // swiftlint:disable:this identifier_name
    /// C6
    case c6 = "C6" // swiftlint:disable:this identifier_name
    /// T8
    case t8 = "T8" // swiftlint:disable:this identifier_name
    /// T10
    case t10 = "T10"
    /// A2
    case a2 = "A2" // swiftlint:disable:this identifier_name

    /// T3
    case t3 = "T3" // swiftlint:disable:this identifier_name
    /// T4
    case t4 = "T4" // swiftlint:disable:this identifier_name
    /// T5
    case t5 = "T5" // swiftlint:disable:this identifier_name
    /// T6
    case t6 = "T6" // swiftlint:disable:this identifier_name

    /// TP9
    case tp9 = "TP9"
    /// TP7
    case tp7 = "TP7"
    /// CP5
    case cp5 = "CP5"
    /// CP3
    case cp3 = "CP3"
    /// CP1
    case cp1 = "CP1"
    /// CPz
    case cpz = "CPz"
    /// CP2
    case cp2 = "CP2"
    /// CP4
    case cp4 = "CP4"
    /// CP6
    case cp6 = "CP6"
    /// TP8
    case tp8 = "TP8"
    /// TP10
    case tp10 = "TP10"
    /// P9
    case p9 = "P9" // swiftlint:disable:this identifier_name

    /// P7
    case p7 = "P7" // swiftlint:disable:this identifier_name
    /// P5
    case p5 = "P5" // swiftlint:disable:this identifier_name
    /// P3
    case p3 = "P3" // swiftlint:disable:this identifier_name
    /// P1
    case p1 = "P1" // swiftlint:disable:this identifier_name
    /// Pz
    case pz = "Pz" // swiftlint:disable:this identifier_name
    /// P2
    case p2 = "P2" // swiftlint:disable:this identifier_name
    /// P4
    case p4 = "P4" // swiftlint:disable:this identifier_name
    /// P6
    case p6 = "P6" // swiftlint:disable:this identifier_name
    /// P8
    case p8 = "P8"
    /// P10
    case p10 = "P10"

    /// PO7
    case po7 = "PO7"
    /// PO3
    case po3 = "PO3"
    /// POz
    case poz = "POz"
    /// PO4
    case po4 = "PO4"
    /// PO8
    case po8 = "PO8"

    /// O1
    case o1 = "O1" // swiftlint:disable:this identifier_name
    /// Oz
    case oz = "Oz" // swiftlint:disable:this identifier_name
    /// O2
    case o2 = "O2" // swiftlint:disable:this identifier_name

    /// Iz
    case iz = "Iz" // swiftlint:disable:this identifier_name
}
