//
//  WidgetLimitRow.swift
//  Claude Monitor Widget
//

import SwiftUI

/// A compact row displaying a single usage limit for the widget.
struct WidgetLimitRow: View {
  let limit: UsageLimit

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text(limit.title)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.primary)
          .lineLimit(1)

        Spacer()

        Text(limit.utilization, format: .percent.precision(.fractionLength(0)))
          .font(.system(size: 11, weight: .regular, design: .monospaced))
          .foregroundStyle(.secondary)

        if let resetsAt = limit.resetsAt {
          Text(resetTimeString(for: resetsAt))
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
        }
      }

      ShadedProgressView(value: limit.utilization, tint: progressColor)
    }
    .frame(maxWidth: 150)
  }

  private var progressColor: Color {
    switch limit.utilization {
      case 0..<0.5: .blue
      case 0.5..<0.8: .yellow
      case 0.8..<0.95: .orange
      default: .red
    }
  }

  private func resetTimeString(for date: Date) -> String {
    let now = Date()
    let interval = date.timeIntervalSince(now)

    guard interval > 0 else { return "" }

    let hours = Int(interval) / 3600
    let days = hours / 24

    if days > 0 {
      return "in \(days)d"
    } else if hours > 0 {
      return "in \(hours)h"
    } else {
      let minutes = Int(interval) / 60
      return "in \(max(1, minutes))m"
    }
  }
}

#Preview {
  VStack(spacing: 8) {
    WidgetLimitRow(limit: UsageLimit(
      id: "session",
      title: "Session",
      utilization: 0.67,
      resetsAt: Date().addingTimeInterval(3600 * 3)
    ))
    WidgetLimitRow(limit: UsageLimit(
      id: "all",
      title: "All",
      utilization: 0.34,
      resetsAt: Date().addingTimeInterval(3600 * 48)
    ))
    WidgetLimitRow(limit: UsageLimit(
      id: "opus",
      title: "Opus",
      utilization: 0.15,
      resetsAt: Date().addingTimeInterval(3600 * 48)
    ))
  }
  .padding()
  .frame(width: 200)
}
