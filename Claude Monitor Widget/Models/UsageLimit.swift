//
//  UsageLimit.swift
//  Claude Monitor Widget
//

import Foundation

/// A usage limit representing a specific quota bucket from the Claude API.
struct UsageLimit: Identifiable {
  /// A unique identifier for this limit, typically matching the API field name.
  let id: String

  /// A localized display title for the limit (e.g., "Current session", "All models").
  let title: String

  /// The utilization percentage as a value between 0.0 and 1.0.
  let utilization: Double

  /// The date when this limit will reset, or `nil` if unknown.
  let resetsAt: Date?
}
