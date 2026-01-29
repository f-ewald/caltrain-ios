//
//  CaltrainWidget.swift
//  CaltrainWidget
//
//  Main widget configuration
//

import WidgetKit
import SwiftUI

struct CaltrainWidget: Widget {
    let kind: String = "CaltrainWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: CaltrainTimelineProvider()
        ) { entry in
            CaltrainWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Caltrain Departures")
        .description("View upcoming train departures at your nearest station")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
