//
//  UsageTimelineProvider.swift
//  Claude Monitor Widget
//

import WidgetKit

/// Provides timeline entries for the Claude Monitor widget.
struct UsageTimelineProvider: TimelineProvider {
  private let apiService = ClaudeAPIService.shared
  private let keychainService = KeychainService.shared

  /// The user's preferred token source.
  /// Note: Without App Groups, we default to Claude Code token.
  /// To enable preference sharing, configure App Groups in Developer Portal.
  private var preferredTokenSource: TokenSource {
    // App Groups not configured - default to Claude Code
    return .claudeCode
  }

  func placeholder(in context: Context) -> UsageEntry {
    .placeholder
  }

  func getSnapshot(in context: Context, completion: @escaping @Sendable (UsageEntry) -> Void) {
    if context.isPreview {
      completion(.placeholder)
      return
    }

    Task { @MainActor in
      let entry = await fetchUsageEntry()
      completion(entry)
    }
  }

  func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<UsageEntry>) -> Void) {
    Task { @MainActor in
      let entry = await fetchUsageEntry()

      // Refresh in 15 minutes
      let nextUpdate = Date().addingTimeInterval(15 * 60)
      let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

      completion(timeline)
    }
  }

  /// Fetches usage data and creates a timeline entry.
  @MainActor
  private func fetchUsageEntry() async -> UsageEntry {
    // Get token
    guard let (token, _) = keychainService.resolveToken(preferredSource: preferredTokenSource) else {
      return .error("No API token configured")
    }

    // Fetch usage
    do {
      let response = try await apiService.fetchUsage(token: token)
      let limits = parseUsageLimits(from: response)
      let sessionUtilization = response.fiveHour.map { $0.utilization / 100.0 }

      return UsageEntry(
        date: Date(),
        limits: limits,
        sessionUtilization: sessionUtilization
      )
    } catch {
      return .error("Failed to fetch usage")
    }
  }

  /// Parses the API response into UsageLimit objects.
  private func parseUsageLimits(from response: UsageResponse) -> [UsageLimit] {
    var limits: [UsageLimit] = []

    if let bucket = response.fiveHour {
      limits.append(UsageLimit(
        id: "five_hour",
        title: "Session",
        utilization: bucket.utilization / 100.0,
        resetsAt: parseDate(bucket.resetsAt)
      ))
    }

    if let bucket = response.sevenDay {
      limits.append(UsageLimit(
        id: "seven_day",
        title: "All",
        utilization: bucket.utilization / 100.0,
        resetsAt: parseDate(bucket.resetsAt)
      ))
    }

    if let bucket = response.sevenDayOpus, bucket.utilization > 0 {
      limits.append(UsageLimit(
        id: "seven_day_opus",
        title: "Opus",
        utilization: bucket.utilization / 100.0,
        resetsAt: parseDate(bucket.resetsAt)
      ))
    }

    if let bucket = response.sevenDaySonnet, bucket.utilization > 0 {
      limits.append(UsageLimit(
        id: "seven_day_sonnet",
        title: "Sonnet",
        utilization: bucket.utilization / 100.0,
        resetsAt: parseDate(bucket.resetsAt)
      ))
    }

    return limits
  }

  /// Parses an ISO 8601 date string.
  private func parseDate(_ string: String?) -> Date? {
    guard let string else { return nil }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    if let date = formatter.date(from: string) {
      return date
    }

    // Try without fractional seconds
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: string)
  }
}
