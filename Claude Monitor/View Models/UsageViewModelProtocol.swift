//
//  UsageViewModelProtocol.swift
//  Claude Monitor
//
//  Created by Tim Morgan on 12/3/25.
//

import Foundation

/// A protocol defining the contract for Claude status view models.
///
/// This protocol enables dependency injection and testability by allowing
/// views to work with either the production ``UsageViewModel`` or
/// the ``MockUsageViewModel`` for previews and testing.
///
/// ## Conforming Types
/// - ``UsageViewModel`` — Production implementation with real API calls
/// - ``MockUsageViewModel`` — Mock implementation for previews
@MainActor
protocol UsageViewModelProtocol: AnyObject, Observable {
  // MARK: - Usage State

  /// Whether the service is still initializing (loading keychain).
  var isInitializing: Bool { get set }

  /// The current usage limits to display.
  var usageLimits: [UsageLimit] { get set }

  /// Whether a refresh operation is in progress.
  var isLoading: Bool { get set }

  /// The last error that occurred, or `nil` if none.
  var error: Error? { get set }

  /// When the usage data was last successfully refreshed.
  var lastUpdated: Date? { get set }

  /// The source of the currently active token.
  var tokenSource: TokenSource? { get set }

  /// Whether a valid token is available for API calls.
  var hasValidToken: Bool { get set }

  // MARK: - Settings State

  /// The user's preferred token source.
  var preferredTokenSource: TokenSource { get set }

  /// The current text in the manual token input field.
  var manualTokenInput: String { get set }

  /// Whether token validation is in progress.
  var isValidatingToken: Bool { get set }

  /// The result of the last token validation attempt.
  var tokenValidationResult: TokenValidationResult? { get set }

  /// Whether a Claude Code token is available in the Keychain.
  var isClaudeCodeTokenAvailable: Bool { get }

  // MARK: - Methods

  /// Refreshes the usage data from the API.
  func refresh() async

  /// Checks and updates token availability state.
  func checkTokenAvailability()

  /// Saves the manual token after a brief delay.
  func saveManualTokenDebounced(_ token: String)

  /// Validates the manually-entered token against the API.
  func validateManualToken() async
}
