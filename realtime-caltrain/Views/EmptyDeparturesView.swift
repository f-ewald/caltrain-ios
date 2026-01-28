//
//  EmptyDeparturesView.swift
//  realtime-caltrain
//
//  Created by Friedrich Ewald on 1/27/26.
//

import SwiftUI

struct EmptyDeparturesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "train.side.front.car")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Station Selected")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Select a station to view upcoming departures")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyDeparturesView()
}
