//
//  UsageDataService.swift
//  Claude Monitor
//
//  Created by Tim Morgan on 12/3/25.
//

import Foundation
import Logging

/// The core service actor that manages usage data fetching, caching, and background refresh.
///
/// `UsageDataService` is a singleton actor that:
/// - Fetches usage data from the Claude API
/// - Maintains cached state (usage limits, errors, token status)
/// - Publishes state changes via `AsyncStream`
/// - Handles background refresh scheduling
///
/// ## Architecture
/// This service owns all business logic. The `UsageViewModel` subscribes
/// to state changes via ``stateStream`` and forwards user actions to this service.
///
/// ## Usage
/// ```swift
/// // Start the service at app launch (from AppDelegate)
/// await UsageDataService.shared.start()
///
/// // Subscribe to state changes (from view model)
/// for await state in UsageDataService.shared.stateStream {
///   // Update UI state
/// }
/// ```
actor UsageDataService {
  /// The shared singleton instance.
  static let shared = UsageDataService()

  // MARK: - State

  /// Whether the service is still initializing (loading keychain).
  private(set) var isInitializing = true

  /// The current usage limits.
  private(set) var usageLimits: [UsageLimit] = []

  /// The last time data was successfully fetched.
  private(set) var lastUpdated: Date?

  /// The most recent error, if any.
  private(set) var error: Error?

  /// The source of the currently active token.
  private(set) var tokenSource: TokenSource?

  /// Whether a valid token is available.
  private(set) var hasValidToken = false

  /// The user's preferred token source.
  private(set) var preferredTokenSource: TokenSource {
    didSet {
      UserDefaults.standard.set(preferredTokenSource.rawValue, forKey: "preferredTokenSource")
    }
  }

  // MARK: - Dependencies
  // Note: These services are Sendable singletons, accessed directly via their static shared property

  // MARK: - Background Refresh

  private let refreshInterval: TimeInterval = 60
  private var backgroundTask: Task<Void, Never>?
  private var isRefreshing = false
  private let logger = Logger(label: "codes.tim.Claude-Monitor.UsageDataService")

  // MARK: - State Publishing

  private var continuations: [UUID: AsyncStream<State>.Continuation] = [:]

  /// An `AsyncStream` that emits state updates.
  ///
  /// Subscribers receive the current state immediately upon subscription,
  /// then receive updates whenever state changes.
  nonisolated var stateStream: AsyncStream<State> {
    AsyncStream { continuation in
      let id = UUID()
      Task {
        await self.addContinuation(continuation, id: id)
      }
      continuation.onTermination = { _ in
        Task {
          await self.removeContinuation(id: id)
        }
      }
    }
  }

  private var currentState: State {
    State(
      isInitializing: isInitializing,
      usageLimits: usageLimits,
      lastUpdated: lastUpdated,
      error: error,
      tokenSource: tokenSource,
      hasValidToken: hasValidToken,
      preferredTokenSource: preferredTokenSource
    )
  }

  /// Whether a Claude Code token is available.
  var isClaudeCodeTokenAvailable: Bool {
    get async {
      await KeychainService.shared.isClaudeCodeTokenAvailable
    }
  }

  /// Whether a manual token is available.
  var isManualTokenAvailable: Bool {
    get async {
      await KeychainService.shared.isManualTokenAvailable
    }
  }

  // MARK: - Initialization

  private init() {
    if let savedSource = UserDefaults.standard.string(forKey: "preferredTokenSource"),
      let source = TokenSource(rawValue: savedSource)
    {
      self.preferredTokenSource = source
    } else {
      self.preferredTokenSource = .claudeCode
    }
  }

  private func addContinuation(_ continuation: AsyncStream<State>.Continuation, id: UUID) {
    continuations[id] = continuation
    // Send current state immediately
    continuation.yield(currentState)
  }

  private func removeContinuation(id: UUID) {
    continuations.removeValue(forKey: id)
  }

  private func publishState() {
    let state = currentState
    for (_, continuation) in continuations {
      continuation.yield(state)
    }
  }

  // MARK: - Public Methods

  /// Starts the service, performing initial setup and beginning background refresh.
  ///
  /// Call this once at app launch from the `AppDelegate`.
  func start() async {
    logger.info("Starting UsageDataService")

    // Request notification permission
    await NotificationService.shared.requestPermission()

    // Check token availability (async keychain access)
    await checkTokenAvailability()

    // Mark initialization complete
    isInitializing = false
    publishState()

    // Perform initial data fetch
    await refresh()

    // Start background refresh
    startBackgroundRefresh()
  }

  /// Fetches fresh usage data from the API.
  ///
  /// If a 401 Unauthorized error occurs, the keychain cache is invalidated
  /// and the refresh is retried once. This handles the case where Claude Code
  /// has refreshed its OAuth token in the background.
  func refresh() async {
    await performRefresh(retryOnAuthFailure: true)
  }

  private func performRefresh(retryOnAuthFailure: Bool) async {
    guard !isRefreshing else { return }
    isRefreshing = true
    defer { isRefreshing = false }

    error = nil

    guard
      let (token, source) = await KeychainService.shared.resolveToken(
        preferredSource: preferredTokenSource
      )
    else {
      logger.warning("No token available for refresh")
      error = APIError.noToken
      hasValidToken = false
      tokenSource = nil
      publishState()
      return
    }

    tokenSource = source
    hasValidToken = true

    do {
      let response = try await ClaudeAPIService.shared.fetchUsage(token: token)
      usageLimits = mapResponseToLimits(response)
      lastUpdated = Date()
      logger.debug("Refreshed usage data", metadata: ["limitCount": "\(usageLimits.count)"])

      // Evaluate limits for notifications
      await NotificationService.shared.evaluateLimits(usageLimits)
    } catch let apiError as APIError {
      // On 401 Unauthorized, invalidate the keychain cache and retry once.
      // Claude Code may have refreshed its OAuth token in the background.
      if case .httpError(statusCode: 401, _) = apiError, retryOnAuthFailure {
        logger.info("Got 401, invalidating keychain cache and retrying")
        await KeychainService.shared.invalidateCache()
        isRefreshing = false
        await performRefresh(retryOnAuthFailure: false)
        return
      }
      logger.error("Failed to refresh usage data", metadata: ["error": "\(apiError)"])
      self.error = apiError
    } catch {
      logger.error("Failed to refresh usage data", metadata: ["error": "\(error)"])
      self.error = error
    }

    publishState()
  }

  /// Sets the preferred token source and refreshes data.
  func setPreferredTokenSource(_ source: TokenSource) async {
    preferredTokenSource = source
    await refresh()
  }

  /// Validates a token against the API.
  ///
  /// - Parameter token: The token to validate.
  /// - Returns: `true` if the token is valid.
  func validateToken(_ token: String) async -> Bool {
    await ClaudeAPIService.shared.validateToken(token)
  }

  /// Saves a manually-entered token to the Keychain.
  ///
  /// - Parameter token: The token to save.
  /// - Throws: A `KeychainError` if saving fails.
  func saveManualToken(_ token: String) async throws {
    try await KeychainService.shared.saveManualToken(token)
    await checkTokenAvailability()
    await refresh()
  }

  /// Clears the manually-entered token from the Keychain.
  func clearManualToken() async throws {
    try await KeychainService.shared.deleteManualToken()
    await checkTokenAvailability()
    usageLimits = []
    lastUpdated = nil
    publishState()
  }

  // MARK: - Private Methods

  private func checkTokenAvailability() async {
    if let (_, source) = await KeychainService.shared.resolveToken(
      preferredSource: preferredTokenSource
    ) {
      tokenSource = source
      hasValidToken = true
    } else {
      tokenSource = nil
      hasValidToken = false
    }
  }

  private func startBackgroundRefresh() {
    backgroundTask?.cancel()

    backgroundTask = Task {
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(refreshInterval))
        guard !Task.isCancelled else { break }
        await refresh()
      }
    }
  }

  private func mapResponseToLimits(_ response: UsageResponse) -> [UsageLimit] {
    var limits: [UsageLimit] = []

    if let fiveHour = response.fiveHour {
      limits.append(
        UsageLimit(
          id: "five_hour",
          title: String(localized: "Current session"),
          utilization: fiveHour.utilization / 100.0,
          resetsAt: parseDate(fiveHour.resetsAt)
        )
      )
    }

    if let sevenDay = response.sevenDay {
      limits.append(
        UsageLimit(
          id: "seven_day",
          title: String(localized: "All models"),
          utilization: sevenDay.utilization / 100.0,
          resetsAt: parseDate(sevenDay.resetsAt)
        )
      )
    }

    if let sonnet = response.sevenDaySonnet, sonnet.utilization > 0 || sonnet.resetsAt != nil {
      limits.append(
        UsageLimit(
          id: "seven_day_sonnet",
          title: String(localized: "Sonnet only"),
          utilization: sonnet.utilization / 100.0,
          resetsAt: parseDate(sonnet.resetsAt)
        )
      )
    }

    if let opus = response.sevenDayOpus, opus.utilization > 0 || opus.resetsAt != nil {
      limits.append(
        UsageLimit(
          id: "seven_day_opus",
          title: String(localized: "Opus only"),
          utilization: opus.utilization / 100.0,
          resetsAt: parseDate(opus.resetsAt)
        )
      )
    }

    return limits
  }

  private func parseDate(_ dateString: String?) -> Date? {
    guard let dateString else { return nil }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    if let date = formatter.date(from: dateString) {
      return date
    }

    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: dateString)
  }

  /// A snapshot of the service's current state.
  struct State: Sendable {
    let isInitializing: Bool
    let usageLimits: [UsageLimit]
    let lastUpdated: Date?
    let error: Error?
    let tokenSource: TokenSource?
    let hasValidToken: Bool
    let preferredTokenSource: TokenSource

    /// A sendable wrapper for the error since Error is not Sendable.
    var errorMessage: String? {
      error?.localizedDescription
    }
  }
}
