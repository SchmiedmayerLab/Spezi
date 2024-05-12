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
    @State private var authorizationStatus = "Unknown"
    
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Authorization Status: \(authorizationStatus)")
            
            if let location {
                Text("Latitude: \(location.coordinate.latitude)")
                Text("Longitude: \(location.coordinate.longitude)")
            } else {
                Text("Location not available")
            }
            
            Spacer()

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
            
            Spacer()
        }
        .buttonStyle(.borderedProminent)
    }
    
    
    private func requestWhenInUseAuthorization() async {
        do {
            let authorizationResult = try await speziLocation.requestWhenInUseAuthorization()

            switch authorizationResult {
            case .authorizedAlways:
                authorizationStatus = "Authorized Always"
            case .notDetermined:
                authorizationStatus = "Not determined"
            case .authorizedWhenInUse:
                authorizationStatus = "Authorized when in use"
            case .denied:
                authorizationStatus = "Denied"
            case .restricted:
                authorizationStatus = "Restricted"
            @unknown default:
                authorizationStatus = "Unknown"
            }
        } catch {
            print("An error occurred.")
        }
    }

    private func getLatestLocation() async {
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
