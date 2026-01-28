//
//  PulsingTrainLoadingView.swift
//  realtime-caltrain
//
//  Created by Claude Code on 1/28/26.
//

import SwiftUI

struct PulsingTrainLoadingView: View {
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 16) {
            Text("🚂")
                .font(.system(size: 60))
                .opacity(isPulsing ? 0.3 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: isPulsing
                )

            Text("Loading departures...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            isPulsing = true
        }
    }
}

#Preview {
    List {
        Section {
            PulsingTrainLoadingView()
        }
    }
}
