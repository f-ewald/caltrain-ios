//
//  Icon.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/9/26.
//

import SwiftUI

struct IconStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)
    }
}

extension View {
    func asIcon() -> some View {
        modifier(IconStyle())
    }
}

struct BikeIcon: View {
    var body: some View {
        Image(systemName: "bicycle").asIcon()
    }
}

struct ParkingIcon: View {
    var body: some View {
        Text("P").asIcon()
    }
}

struct RestroomIcon: View {
    var body: some View {
        Image(systemName: "toilet").asIcon()
    }
}

#Preview {
    HStack {
        BikeIcon()
        ParkingIcon()
        RestroomIcon()
    }
}
