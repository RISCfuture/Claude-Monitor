//
//  UsageEntry.swift
//  Claude Monitor Widget
//

import WidgetKit

/// A timeline entry containing usage data for the widget.
struct UsageEntry: TimelineEntry {
  /// The date for this entry.
  let date: Date

  /// The usage limits to display.
  let limits: [UsageLimit]

  /// The session (5-hour) utilization for the gauge, or nil if unavailable.
  let sessionUtilization: Double?

  /// An error message if data could not be fetched.
  let error: String?

  /// Whether this is placeholder data.
  let isPlaceholder: Bool

  init(
    date: Date,
    limits: [UsageLimit],
    sessionUtilization: Double?,
    error: String? = nil,
    isPlaceholder: Bool = false
  ) {
    self.date = date
    self.limits = limits
    self.sessionUtilization = sessionUtilization
    self.error = error
    self.isPlaceholder = isPlaceholder
  }

  /// A placeholder entry for the widget gallery.
  static var placeholder: UsageEntry {
    UsageEntry(
      date: Date(),
      limits: [
        UsageLimit(id: "session", title: "Session", utilization: 0.45, resetsAt: Date().addingTimeInterval(3600 * 3)),
        UsageLimit(id: "all", title: "All", utilization: 0.32, resetsAt: Date().addingTimeInterval(3600 * 48)),
        UsageLimit(id: "opus", title: "Opus", utilization: 0.12, resetsAt: Date().addingTimeInterval(3600 * 48))
      ],
      sessionUtilization: 0.45,
      isPlaceholder: true
    )
  }

  /// An error entry when data cannot be fetched.
  static func error(_ message: String) -> UsageEntry {
    UsageEntry(
      date: Date(),
      limits: [],
      sessionUtilization: nil,
      error: message
    )
  }
}
