//
//  StationDetail.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/9/26.
//

import SwiftUI
import MapKit
import Contacts

struct IdentifiablePlace: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct StationDetail: View {
    @Environment(\.dismiss) private var dismiss
    let station: CaltrainStation
    
    @State private var cameraPosition: MapCameraPosition
    private var annotations: [IdentifiablePlace]
    
    init(station: CaltrainStation) {
        self.station = station
        let region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                _cameraPosition = State(initialValue: .region(region))
        self.annotations = [
            IdentifiablePlace(
                name: station.name,
                coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
            )
        ]
    }
    
    /// Open Apple Maps with station as destination
    func openMap() {
        if let url = URL(string: "maps://?saddr=&daddr=\(station.address ?? "")") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func formattedAddress(for station: CaltrainStation) -> String {
        let address = CNMutablePostalAddress()
        address.street = String(format: "%@ %@", station.addressNumber ?? "", station.addressStreet ?? "")
        address.city = station.addressCity ?? ""
        address.postalCode = station.addressPostalCode ?? ""
        address.city = station.addressCity ?? ""
        address.state = station.addressState ?? ""
        
        let formatter = CNPostalAddressFormatter()
        formatter.style = .mailingAddress
        return formatter.string(from: address)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Map(position: $cameraPosition) {
                        Marker(station.name, coordinate: station.location.coordinate)
                            .tint(.red)
                    }
                    .mapControls {
                                MapCompass()
                    }
                    .frame(height: 200)
                    HStack {
                        Button(action: openMap) {
                            Label(formattedAddress(for: station), systemImage: "map")
                        }
                    }
                    
                    HStack {
                        Text("Elevator")
                        Spacer()
                        Text(station.hasElevator ? "Yes" : "No")
                    }
                    if station.hasParking {
                        HStack {
                            Text("Parking")
                            Spacer()
                            ParkingIcon()
                        }
                    }
                    HStack {
                        Text("Zone")
                        Spacer()
                        ZoneTextView(zone: station.zoneNumber)
                    }
                    
                    if station.bikeRacks != nil {
                        HStack {
                            Text("Bike Racks")
                            Spacer()
                            BikeIcon()
                            Text(String(format: "%d", station.bikeRacks ?? 0))
                        }
                    }
                    if let ticketMachines = station.ticketMachines {
                        HStack {
                            Text("Ticket Machines")
                            Spacer()
                            Text(String(format: "%d", ticketMachines))
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle(station.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityIdentifier("station.detail.close")
                }
            }
        }
    }
}

#Preview {
    StationDetail(station: CaltrainStation.exampleStation)
}
