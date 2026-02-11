//
//  CaltrainWidget.swift
//  CaltrainWidget
//
//  Main widget configuration
//

import WidgetKit
import SwiftUI

struct CaltrainWidget: Widget {
    /// Kind of the widget
    let kind: String = "net.fewald.caltrain.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CaltrainConfigurationIntent.self, provider: CaltrainTimelineProvider()) { entry in CaltrainWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget) }
        .configurationDisplayName("Caltrain Departures")
        .description("View upcoming train departures")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Previews

#Preview("Medium - Sample", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sample
}

#Preview("Large - Sample", as: .systemLarge) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sample
}

#Preview("Medium - No Location", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry(
        date: Date(),
        configuration: CaltrainConfigurationIntent(),
        station: nil,
        northboundDepartures: [],
        southboundDepartures: [],
        error: .noLocation,
        debugMessage: nil,
    )
}

#Preview("Large - Error", as: .systemLarge) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry(
        date: Date(),
        configuration: CaltrainConfigurationIntent(),
        station: nil,
        northboundDepartures: [],
        southboundDepartures: [],
        error: .apiError,
        debugMessage: nil,
    )
}
