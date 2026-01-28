//
//  LocationManager.swift
//  realtime-caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import Foundation
import CoreLocation
import Observation

/// Errors that can occur during location services operations
enum LocationError: Error, LocalizedError {
    case denied
    case restricted
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .denied:
            return "Location access denied. Please enable location services in Settings."
        case .restricted:
            return "Location access is restricted. This may be due to parental controls or device management."
        case .unknownError(let error):
            return "Location error: \(error.localizedDescription)"
        }
    }
}

/// Observable location manager that wraps CLLocationManager for SwiftUI integration
@Observable
final class LocationManager: NSObject {
    // MARK: - Observable Properties

    /// The most recent location update
    private(set) var location: CLLocation?

    /// Current authorization status for location services
    private(set) var authorizationStatus: CLAuthorizationStatus

    /// Any error that occurred during location operations
    private(set) var error: LocationError?

    // MARK: - Private Properties

    private let locationManager: CLLocationManager

    // MARK: - Computed Properties

    /// Whether the app is authorized to access location services
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    /// Whether a location is currently available
    var isLocationAvailable: Bool {
        location != nil
    }

    // MARK: - Initialization

    override init() {
        self.locationManager = CLLocationManager()
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }

    // MARK: - Public Methods

    /// Request when-in-use authorization for location services
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Start receiving location updates
    func startUpdating() {
        guard isAuthorized else {
            error = .denied
            return
        }

        error = nil
        locationManager.startUpdatingLocation()
    }

    /// Stop receiving location updates
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // Clear any previous errors when authorization changes
        error = nil

        // Handle authorization status changes
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Auto-start updates when authorized
            startUpdating()

        case .denied:
            error = .denied
            stopUpdating()

        case .restricted:
            error = .restricted
            stopUpdating()

        case .notDetermined:
            // Waiting for user decision
            break

        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        location = latestLocation
        error = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle specific Core Location errors
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                self.error = .denied
            case .locationUnknown:
                // Temporary error, don't update error state
                break
            default:
                self.error = .unknownError(error)
            }
        } else {
            self.error = .unknownError(error)
        }
    }
}
