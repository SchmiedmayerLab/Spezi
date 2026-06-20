#!/usr/bin/env bash
#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#
# Reproduces the union CI testing matrix of the original input packages using Xcode test plans.
# Each former package has a test plan under Tests/TestPlans/<Package>.xctestplan, all hosted by the
# single "Spezi-Tests" scheme. This script runs a given package's tests on a given platform (or on
# every platform that package was tested on upstream), or runs the whole suite on iOS.
#
# Usage:
#   Scripts/run-package-tests.sh <Package> [Platform]   # one package on one platform (default: all its platforms)
#   Scripts/run-package-tests.sh --all-ios              # the entire package's tests on the iOS Simulator
#   Scripts/run-package-tests.sh --list                 # print the package -> platforms matrix
#
# Platforms: iOS macOS macCatalyst watchOS visionOS tvOS
set -euo pipefail
cd "$(dirname "$0")/.."

PACKAGES="FHIRModelsExtensions HealthKitOnFHIR ResearchKitOnFHIR Spezi SpeziAccessGuard SpeziAccount SpeziBluetooth SpeziChat SpeziConsent SpeziContact SpeziDevices SpeziFHIR SpeziFileFormats SpeziFirebase SpeziFoundation SpeziHealthKit SpeziLLM SpeziLicense SpeziLocation SpeziMedication SpeziNetworking SpeziNotifications SpeziOnboarding SpeziQuestionnaire SpeziScheduler SpeziSensorKit SpeziSpeech SpeziStorage SpeziStudy SpeziViews ThreadLocal XCTHealthKit XCTRuntimeAssertions XCTestExtensions"

# package -> the platforms it was tested on upstream (the union CI matrix)
platforms_for() { case "$1" in
    FHIRModelsExtensions) echo "iOS macOS macCatalyst watchOS visionOS tvOS" ;;
    HealthKitOnFHIR) echo "iOS macOS watchOS" ;;
    ResearchKitOnFHIR) echo "iOS" ;;
    Spezi) echo "iOS visionOS macOS tvOS watchOS macCatalyst" ;;
    SpeziAccessGuard) echo "iOS" ;;
    SpeziAccount) echo "macOS" ;;
    SpeziBluetooth) echo "iOS macOS macCatalyst watchOS visionOS tvOS" ;;
    SpeziChat) echo "iOS macOS visionOS" ;;
    SpeziConsent) echo "iOS macOS visionOS" ;;
    SpeziContact) echo "iOS" ;;
    SpeziDevices) echo "iOS macOS macCatalyst visionOS" ;;
    SpeziFHIR) echo "iOS" ;;
    SpeziFileFormats) echo "iOS watchOS visionOS tvOS macOS" ;;
    SpeziFirebase) echo "iOS" ;;
    SpeziFoundation) echo "iOS macOS macCatalyst watchOS visionOS tvOS" ;;
    SpeziHealthKit) echo "iOS watchOS macOS macCatalyst visionOS" ;;
    SpeziLLM) echo "iOS visionOS macOS" ;;
    SpeziLicense) echo "iOS" ;;
    SpeziLocation) echo "iOS watchOS" ;;
    SpeziMedication) echo "iOS" ;;
    SpeziNetworking) echo "iOS watchOS visionOS tvOS macOS" ;;
    SpeziNotifications) echo "iOS macOS watchOS visionOS tvOS" ;;
    SpeziOnboarding) echo "iOS macOS visionOS" ;;
    SpeziQuestionnaire) echo "iOS" ;;
    SpeziScheduler) echo "iOS macOS visionOS watchOS" ;;
    SpeziSensorKit) echo "iOS" ;;
    SpeziSpeech) echo "iOS visionOS macOS" ;;
    SpeziStorage) echo "iOS macOS macCatalyst watchOS visionOS" ;;
    SpeziStudy) echo "iOS macOS macCatalyst watchOS visionOS" ;;
    SpeziViews) echo "iOS visionOS tvOS watchOS macOS" ;;
    ThreadLocal) echo "macOS iOS macCatalyst watchOS visionOS tvOS" ;;
    XCTHealthKit) echo "iOS" ;;
    XCTRuntimeAssertions) echo "iOS macOS macCatalyst watchOS visionOS tvOS" ;;
    XCTestExtensions) echo "iOS watchOS visionOS macOS" ;;
    *) echo "" ;;
  esac; }

dest() { case "$1" in
  iOS)          echo "platform=iOS Simulator,name=iPhone 17 Pro" ;;
  macOS)        echo "platform=macOS,arch=arm64" ;;
  macCatalyst)  echo "platform=macOS,arch=arm64,variant=Mac Catalyst" ;;
  watchOS)      echo "platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)" ;;
  visionOS)     echo "platform=visionOS Simulator,name=Apple Vision Pro" ;;
  tvOS)         echo "platform=tvOS Simulator,name=Apple TV 4K (3rd generation)" ;;
  *) echo "unknown platform: $1" >&2; exit 2 ;;
esac; }

# Pretty-print xcodebuild output via xcbeautify; emit GitHub annotations when running in CI.
beautify() { if [ -n "${GITHUB_ACTIONS:-}" ]; then xcbeautify --renderer github-actions; else xcbeautify; fi; }

run() { # <testplan> <platform>
  echo "==> $1 on $2"
  xcodebuild test \
    -scheme Spezi-Tests \
    -testPlan "$1" \
    -destination "$(dest "$2")" \
    -skipMacroValidation \
    -skipPackagePluginValidation \
    -derivedDataPath ".derivedData" \
  | beautify
}

case "${1:-}" in
  --list)
    for p in $PACKAGES; do printf '%-24s %s\n' "$p" "$(platforms_for "$p")"; done ;;
  --all-ios)
    echo "==> entire package on iOS Simulator"
    xcodebuild test -scheme Spezi-Package -destination "$(dest iOS)" \
      -skipMacroValidation -skipPackagePluginValidation | beautify ;;
  "")
    echo "usage: $0 <Package> [Platform] | --all-ios | --list" >&2; exit 1 ;;
  *)
    PKG="$1"
    PLATS="$(platforms_for "$PKG")"
    [ -n "$PLATS" ] || { echo "unknown package: $PKG (see --list)" >&2; exit 1; }
    if [ "${2:-}" ]; then run "$PKG" "$2"
    else for plat in $PLATS; do run "$PKG" "$plat"; done; fi ;;
esac
