//
//  UsageWidgetView.swift
//  Claude Monitor Widget
//

import SwiftUI
import WidgetKit
import AppIntents

/// The main widget view for the medium size widget.
struct UsageWidgetView: View {
  let entry: UsageEntry

  var body: some View {
    if let error = entry.error {
      errorView(message: error)
    } else if entry.limits.isEmpty {
      emptyView
    } else {
      contentView
    }
  }

  private var contentView: some View {
    Button(intent: RefreshIntent()) {
      HStack(spacing: 28) {
        // Gauge on the left
        GaugeView(
          utilization: entry.sessionUtilization ?? 0,
          size: 70
        )
        .padding(.leading, 4)

        // Limits on the right
        VStack(alignment: .leading, spacing: 6) {
          Spacer(minLength: 4)

          ForEach(entry.limits.prefix(3)) { limit in
            WidgetLimitRow(limit: limit)
          }

          Spacer(minLength: 8)
        }
        .padding(.trailing, 4)
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 4)
    }
    .buttonStyle(.plain)
  }

  private func errorView(message: String) -> some View {
    VStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text(message)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button(intent: RefreshIntent()) {
        Text("Retry")
          .font(.caption)
      }
      .buttonStyle(.plain)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var emptyView: some View {
    VStack(spacing: 8) {
      Image(systemName: "chart.bar")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text("No usage data")
        .font(.caption)
        .foregroundStyle(.secondary)

      Button(intent: RefreshIntent()) {
        Text("Refresh")
          .font(.caption)
      }
      .buttonStyle(.plain)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview(as: .systemMedium) {
  Claude_Monitor_Widget()
} timeline: {
  UsageEntry.placeholder
  UsageEntry(
    date: Date(),
    limits: [
      UsageLimit(id: "session", title: "Session", utilization: 0.67, resetsAt: Date().addingTimeInterval(3600 * 3)),
      UsageLimit(id: "all", title: "All", utilization: 0.34, resetsAt: Date().addingTimeInterval(3600 * 48)),
      UsageLimit(id: "opus", title: "Opus", utilization: 0.15, resetsAt: Date().addingTimeInterval(3600 * 48))
    ],
    sessionUtilization: 0.67
  )
  UsageEntry.error("No API token configured")
}
