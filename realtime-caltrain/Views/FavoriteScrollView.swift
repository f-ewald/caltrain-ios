//
//  FavoriteScrollView.swift
//  caltrain
//
//  Created by Friedrich Ewald on 2/13/26.
//

import SwiftData
import SwiftUI

struct FavoriteScrollView: View {
    
    @Query
    private var allStations: [CaltrainStation]
    
    @Query(filter: #Predicate<CaltrainStation> { station in station.isFavorite }, sort: \CaltrainStation.shortCode)
    private var favoriteStations: [CaltrainStation]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(favoriteStations, id: \.self) { station in
                    Button {
                        #if DEBUG
                        print("Station \(station.name) selected")
                        #endif
                        withAnimation {
                            StationSelectionService.selectStation(station, from: allStations)
                        }
                    }
                    label: {
                        Text(station.shortCode.uppercased())
                            .bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("favorite.station.\(station.shortCode)")
                }
            }
        }
    }
}

#Preview {
    FavoriteScrollView().modelContainer(SampleData.container)
}
