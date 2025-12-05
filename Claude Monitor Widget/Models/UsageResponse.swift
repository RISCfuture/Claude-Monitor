//
//  UsageResponse.swift
//  Claude Monitor Widget
//

import Foundation

/// The raw JSON response from the Anthropic OAuth usage API endpoint.
struct UsageResponse: Codable {
  /// The 5-hour rolling session limit.
  let fiveHour: UsageBucket?

  /// The 7-day combined usage limit across all models.
  let sevenDay: UsageBucket?

  /// The 7-day usage limit for OAuth applications.
  let sevenDayOauthApps: UsageBucket?

  /// The 7-day usage limit specifically for Claude Opus.
  let sevenDayOpus: UsageBucket?

  /// The 7-day usage limit specifically for Claude Sonnet.
  let sevenDaySonnet: UsageBucket?

  enum CodingKeys: String, CodingKey {
    case fiveHour = "five_hour"
    case sevenDay = "seven_day"
    case sevenDayOauthApps = "seven_day_oauth_apps"
    case sevenDayOpus = "seven_day_opus"
    case sevenDaySonnet = "seven_day_sonnet"
  }
}

/// A single usage bucket from the API response.
struct UsageBucket: Codable {
  /// The current utilization as a percentage (0-100).
  let utilization: Double

  /// The ISO 8601 timestamp when this limit will reset, or `nil` if not applicable.
  let resetsAt: String?

  enum CodingKeys: String, CodingKey {
    case utilization
    case resetsAt = "resets_at"
  }
}
