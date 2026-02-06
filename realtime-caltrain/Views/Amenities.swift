//
//  Amenities.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/5/26.
//

import SwiftUI

struct Amenities : View {
    let parkingSpaces: Int
    let bikeRacks: Int
    let hasRestrooms: Bool
    let hasElevator: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            if parkingSpaces > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "parkingsign.circle.fill")
                    Text("\(parkingSpaces)")
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
            
            if bikeRacks > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "bicycle.circle.fill")
                    Text("\(bikeRacks)")
                }
                .font(.caption)
                .foregroundStyle(.green)
            }
            
            if hasRestrooms {
                Image(systemName: "toilet.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.purple)
            }
            
            if hasElevator {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}

#Preview {
    Amenities(
        parkingSpaces: 3,
        bikeRacks: 178,
        hasRestrooms: true,
        hasElevator: true
    )
}
