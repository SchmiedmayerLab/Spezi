# ``SpeziSensorKit``

<!--

This source file is part of the SpeziSensorKit open source project

SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
       
-->

Interact with SensorKit in your Spezi application

## Overview
The Spezi SensorKit module enables apps to integrate with Apple's [SensorKit](https://developer.apple.com/documentation/sensorkit) system, such as requesting authorization, setting up background data collection, and fetching collected samples.

### Setup
You need to add the Spezi SensorKit Swift package to
 [your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app) or
 [Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the
 [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) and set up the core Spezi infrastructure. 


### SensorKit Entitlements

In order to use SensorKit in your app, you need to list each sensor you want to access in your app's entitlements file.

Create an entry for the `com.apple.developer.sensorkit.reader.allow` key, of type array, and add each sensor's key to that array.

| Sensor                      | Entitlement            |
| :-------------------------- | :--------------------- |
| ``Sensor/accelerometer``    | `motion-accelerometer` |
| ``Sensor/ambientLight``     | `ambient-light-sensor` |
| ``Sensor/ambientPressure``  | `ambient-pressure`     |
| ``Sensor/deviceUsage``      | `device-usage`         |
| ``Sensor/ecg``              | `ECG`                  |
| ``Sensor/heartRate``        | `heart-rate`           |
| ``Sensor/onWrist``          | `on-wrist`             |
| ``Sensor/pedometer``        | `pedometer`            |
| ``Sensor/ppg``              | `PPG`                  |
| ``Sensor/visits``           | `visits`               |
| ``Sensor/wristTemperature`` | `wrist-temperature`    |


### Example
You use the ``SensorReader`` type to fetch data from SensorKit.
First, fetch a list of all devices from which SensorKit has data for the sensor you want to query.
Then, fetch each device's samples using the ``SensorReader/fetch(from:timeRange:)`` or ``SensorReader/fetch(from:mostRecentAvailable:)`` functions.

> Note: SensorKit enforces a quarantine period for each sensor's data; apps can only access data once a certain, sensor-specific time period has passed.
  SpeziSensorKit is aware of each sensor's ``Sensor/dataQuarantineDuration`` and will automatically adjust your fetch requests to not overlap with the quarantine time periods.

#### Fetch Results
SensorKit returns samples as an Array of `SRFetchResult` objects, each of which contains one or more samples.
For most sensors, the `SRFetchResult` contains only a single sample

```swift
import SpeziSensorKit

let reader = SensorReader(.heartRate)
let devices = try await reader.fetchDevices()
for device in devices {
    let results = try await reader.fetch(from: device, mostRecentAvailable: .days(7))
    for sample in results.lazy.flatMap(\.samples) {
        print(sample.date, sample.heartRate, sample.confidence)
    }
}
```

### Performance Considerations
The amount of samples collected varies significantly across the different sensors.
While some of them collect only a small number of samples, some others (e.g., ``Sensor/ambientPressure``) will collect large amounts of data; fetching too many samples at once, or using inefficient Array-based operations will incur performance penalties and might cause your app to crash if it runs out of memory.

Make sure in your app to use lazy sequence/collection operations when possible when working with SensorKit data (see e.g. the example above).

Additionally, SpeziSensorKit offers the ``SensorKit/FetchResultsIterator`` to efficiently process individual samples alongside their SensorKit timestamps, without unnecessary intermediate allocations. 


### Threading Considerations
Avoid accessing the same ``Sensor`` from multiple threads at the same time, even if using different ``SensorReader`` instances.



## Topics

### The SensorKit Module
- ``SensorKit``

### Permission Handling
- ``SensorKit/authorizationStatus(for:)``
- ``SensorKit/requestAccess(to:)``

### Working with Sensors 
- ``Sensor``
- ``SensorReader``

### Supporting Types
- ``SensorKitActor``
