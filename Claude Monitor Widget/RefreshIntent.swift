//
//  RefreshIntent.swift
//  Claude Monitor Widget
//

import AppIntents
import WidgetKit

/// An App Intent that refreshes the widget's data.
struct RefreshIntent: AppIntent {
  static let title: LocalizedStringResource = "Refresh Usage"
  static let description: IntentDescription = "Refreshes the Claude usage data"

  func perform() async throws -> some IntentResult {
    // Trigger a timeline refresh
    WidgetCenter.shared.reloadAllTimelines()
    return .result()
  }
}
