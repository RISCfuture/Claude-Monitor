//
//  Claude_Monitor_Widget.swift
//  Claude Monitor Widget
//

import SwiftUI
import WidgetKit

/// The Claude Monitor widget displaying API usage.
struct Claude_Monitor_Widget: Widget {
  let kind: String = "Claude_Monitor_Widget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: UsageTimelineProvider()) { entry in
      UsageWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Claude Usage")
    .description("Monitor your Claude API usage limits.")
    .supportedFamilies([.systemMedium])
  }
}
