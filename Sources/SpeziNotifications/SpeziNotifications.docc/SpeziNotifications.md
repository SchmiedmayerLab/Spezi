# ``SpeziNotifications``

<!--

This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT

-->

Simplify User Notifications in Spezi-based applications.

## Overview

SpeziNotifications simplifies interaction with user notifications by adding additional actions to the Environment of SwiftUI Views and
Spezi Modules.

### Schedule Notifications

You can use the ``Notifications`` module to interact with user notifications within your application. You can either define it as a dependency
of your Spezi [`Module`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module)
or retrieve it from the environment using the [`@Environment`](https://developer.apple.com/documentation/swiftui/environment)
property wrapper in your SwiftUI View.

The code example below schedules a notification request, accessing the `Notifications` module from within the custom `MyNotifications` module.

```swift
import Spezi
import UserNotifications


final class MyNotifications: Module {
    @Dependency(Notifications.self)
    private var notifications

    @Application(\.notificationSettings)
    private var settings

    func scheduleAppointmentReminder() async throws {
        let status = await settings().authorizationStatus
        guard status == .authorized || status == .provisional else {
            return // no authorization to schedule notification
        }

        let content = UNMutableNotificationContent()
        content.title = "Your Appointment"
        content.body = "Your appointment is in 3 hours"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3 * 60, repeats: false)

        let request = UNNotificationRequest(identifier: "3-hour-reminder", content: content, trigger: trigger)

        try await notifications.add(request: request)
    }
}
```

### Requesting Authorization in SwiftUI

The Notification module and notification-related actions are also available in the SwiftUI Environment. The code example below creates a simple
notification authorization onboarding view that (1) determines the current authorization status and (2) request notification authorization
when the user taps the button.


```swift
import SpeziNotifications
import SpeziViews

struct NotificationOnboarding: View {
    @Environment(\.notificationSettings)
    private var notificationSettings
    @Environment(\.requestNotificationAuthorization)
    private var requestNotificationAuthorization

    @State private var viewState: ViewState = .idle
    @State private var notificationsAuthorized = false

    var body: some View {
        VStack {
            // ...
            if notificationsAuthorized {
                Button("Continue") {
                    // show next view ...
                }
            } else {
                AsyncButton("Allow Notifications", state: $viewState) {
                    try await requestNotificationAuthorization(options: [.alert, .badge, .sound])
                }
                    .environment(\.defaultErrorDescription, "Failed to request notification authorization.")
            }
        }
            .viewStateAlert(state: $viewState)
            .task {
                notificationsAuthorized = await notificationSettings().authorizationStatus == .authorized
            }
    }
}
```

- Important: The example above uses the [`AsyncButton`](https://swiftpackageindex.com/stanfordspezi/speziviews/documentation/speziviews/asyncbutton)
    and the [`ViewState`](https://swiftpackageindex.com/stanfordspezi/speziviews/documentation/speziviews/viewstate) model from SpeziViews to more
    easily manage the state of asynchronous actions and handle erroneous conditions.

## Topics

### Notifications
- ``Notifications``
- ``NotificationHandler``
- ``BackgroundFetchResult``

### Notification Authorization
- ``Spezi/Spezi/notificationSettings``
- ``SwiftUICore/EnvironmentValues/notificationSettings``
- ``Spezi/Spezi/requestNotificationAuthorization``
- ``SwiftUICore/EnvironmentValues/requestNotificationAuthorization``

### Remote Notifications
- ``NotificationTokenHandler``
- ``Spezi/Spezi/registerRemoteNotifications``
- ``SwiftUICore/EnvironmentValues/registerRemoteNotifications``
- ``Spezi/Spezi/unregisterRemoteNotifications``
- ``SwiftUICore/EnvironmentValues/unregisterRemoteNotifications``
