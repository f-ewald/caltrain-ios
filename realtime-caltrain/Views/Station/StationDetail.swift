//
//  StationDetail.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/9/26.
//

import SwiftUI
import MapKit

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
                    if let address = station.address {
                        HStack {
                            Button(action: openMap) {
                                Label(address, systemImage: "map")
                            }
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
                }
            }
        }
    }
}

#Preview {
    let station = CaltrainStation(stationId: "sf", name: "San Francisco", shortCode: "sf", gtfsStopIdSouth: "1", gtfsStopIdNorth: "2", latitude: 37.776439, longitude: -122.394434, zoneNumber: 1, address: "700 4th St., San Francisco 94107", hasParking: true, hasBikeParking: false, parkingSpaces: 20, bikeRacks: 10, hasBikeLockers: true, hasRestrooms: false, ticketMachines: 6, hasElevator: false, isFavorite: false, isSelected: false)
    StationDetail(station: station)
}
