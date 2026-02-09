//
//  ZoneTextView.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/9/26.
//

import SwiftUI

struct ZoneTextView: View {
    let zone: Int
    var body: some View {
        Text("Zone \(zone)").asIcon()
    }
}

#Preview {
    ZoneTextView(zone: 1)
}
