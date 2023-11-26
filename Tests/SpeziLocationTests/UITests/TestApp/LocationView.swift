//
// This source file is part of the SpeziLocation open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CoreLocation
import SpeziLocation
import SwiftUI

struct LocationView: View {
    @Environment(SpeziLocation.self) private var speziLocation
    @State private var location: CLLocation?

    var body: some View {
        VStack {
            if let location = location {
                Text("Latitude: \(location.coordinate.latitude)")
                Text("Longitude: \(location.coordinate.longitude)")
            } else {
                Text("Location not available")
            }

            Button("Request When In Use Permission") {
                Task {
                    await requestWhenInUseAuthorization()
                }
            }
            
            Button("Current Location") {
                Task {
                    await getLatestLocation()
                }
            }
        }
        .buttonStyle(.borderedProminent)
    }

    func requestWhenInUseAuthorization() async {
        do {
            let authorized = try await self.speziLocation.requestWhenInUseAuthorization()

            switch authorized {
            case .authorizedAlways:
                print("Authorized Always")
            case .notDetermined:
                print("Not determined")
            case .authorizedWhenInUse:
                print("Authorized when in use")
            case .denied:
                print("Denied")
            case .restricted:
                print("Restricted")
            @unknown default:
                print("Unknown")
            }
        } catch {
            print("An error occurred.")
        }
    }

    func getLatestLocation() async {
        do {
            let locations = try await speziLocation.getLatestLocations()
            self.location = locations.last
        } catch {
            print("An error occurred.")
        }
    }
}

#Preview {
    LocationView()
}
