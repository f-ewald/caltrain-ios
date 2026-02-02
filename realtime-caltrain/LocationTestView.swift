//
//  LocationTestView.swift
//  caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI
import CoreLocation

struct LocationTestView: View {
    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        List {
            // Authorization Status Section
            Section {
                HStack {
                    Text("Status")
                        .fontWeight(.medium)
                    Spacer()
                    Text(authorizationStatusText)
                        .foregroundStyle(authorizationStatusColor)
                }
            } header: {
                Text("Authorization")
            }

            // Location Information Section
            if locationManager.isLocationAvailable, let location = locationManager.location {
                Section {
                    LabeledContent("Latitude", value: String(format: "%.6f", location.coordinate.latitude))
                    LabeledContent("Longitude", value: String(format: "%.6f", location.coordinate.longitude))
                    LabeledContent("Accuracy", value: String(format: "%.1f meters", location.horizontalAccuracy))
                    LabeledContent("Altitude", value: String(format: "%.1f meters", location.altitude))
                    LabeledContent("Timestamp", value: location.timestamp.formatted(date: .omitted, time: .standard))
                } header: {
                    Text("Current Location")
                }
            }

            // Error Section
            if let error = locationManager.error {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)

                        if case .denied = error {
                            Button("Open Settings") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Error")
                }
            }

            // Actions Section
            Section {
                if locationManager.authorizationStatus == .notDetermined {
                    Button("Request Permission") {
                        locationManager.requestPermission()
                    }
                }

                if locationManager.isAuthorized {
                    Button("Start Updates") {
                        locationManager.startUpdating()
                    }
                    .disabled(locationManager.isLocationAvailable)

                    Button("Stop Updates") {
                        locationManager.stopUpdating()
                    }
                    .foregroundStyle(.red)
                }
            } header: {
                Text("Actions")
            }

            // Information Section
            Section {
                Text("This view allows you to test location services functionality. Grant permission to start receiving location updates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Location Test")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Computed Properties

    private var authorizationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Authorized (Always)"
        case .authorizedWhenInUse:
            return "Authorized (When In Use)"
        @unknown default:
            return "Unknown"
        }
    }

    private var authorizationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return .green
        case .denied:
            return .red
        case .restricted:
            return .orange
        case .notDetermined:
            return .secondary
        @unknown default:
            return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LocationTestView()
            .environment(LocationManager())
    }
}
