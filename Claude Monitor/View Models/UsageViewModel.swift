//
//  UsageViewModel.swift
//  Claude Monitor
//
//  Created by Tim Morgan on 12/3/25.
//

import Foundation
import Observation
import SwiftUI

/// The result of validating a token against the API.
enum TokenValidationResult {
  /// The token is valid and can access the API.
  case valid

  /// The token is invalid or expired.
  case invalid
}

/// A thin view model that subscribes to `UsageDataService` for state updates.
///
/// `UsageViewModel` bridges the `UsageDataService` actor with SwiftUI views.
/// It subscribes to the service's `AsyncStream` and updates its observable properties
/// when state changes. UI-only state (like loading indicators and form fields) is
/// managed locally.
///
/// ## Architecture
/// - **Service State**: `usageLimits`, `lastUpdated`, `error`, `tokenSource`, `hasValidToken`
///   are synced from `UsageDataService` via `AsyncStream`
/// - **UI State**: `isLoading`, `manualTokenInput`, `isValidatingToken`, etc.
///   are managed locally for UI responsiveness
///
/// ## Usage
/// ```swift
/// @State private var viewModel = UsageViewModel()
///
/// var body: some View {
///   ContentView()
///     .viewModel(viewModel)
/// }
/// ```
@Observable
@MainActor
final class UsageViewModel: UsageViewModelProtocol {
  // MARK: - State from Service (synced via AsyncStream)

  var isInitializing = true
  var usageLimits: [UsageLimit] = []
  var lastUpdated: Date?
  var error: Error?
  var tokenSource: TokenSource?
  var hasValidToken = false

  // MARK: - UI-Only State

  var isLoading = false
  var manualTokenInput = ""
  var isValidatingToken = false
  var tokenValidationResult: TokenValidationResult?

  var preferredTokenSource: TokenSource {
    didSet {
      guard oldValue != preferredTokenSource else { return }
      UserDefaults.standard.set(preferredTokenSource.rawValue, forKey: "preferredTokenSource")
      Task {
        await UsageDataService.shared.setPreferredTokenSource(preferredTokenSource)
      }
    }
  }

  // MARK: - Private State

  private var subscriptionTask: Task<Void, Never>?
  private var saveTask: Task<Void, Never>?

  // MARK: - Protocol Conformance

  /// Whether a Claude Code token is available. Updated asynchronously from service.
  private(set) var isClaudeCodeTokenAvailable = false

  // MARK: - Initialization

  init() {
    // Initialize from UserDefaults to match service state before stream connects
    if let savedSource = UserDefaults.standard.string(forKey: "preferredTokenSource"),
      let source = TokenSource(rawValue: savedSource)
    {
      self.preferredTokenSource = source
    } else {
      self.preferredTokenSource = .claudeCode
    }

    startSubscription()
    loadManualTokenAsync()
  }

  /// Loads the manual token asynchronously to avoid blocking main thread.
  private func loadManualTokenAsync() {
    Task {
      if let token = try? await KeychainService.shared.readManualToken() {
        self.manualTokenInput = token
      }
      self.isClaudeCodeTokenAvailable = await KeychainService.shared.isClaudeCodeTokenAvailable
    }
  }

  // MARK: - Subscription

  private func startSubscription() {
    subscriptionTask = Task { [weak self] in
      for await state in UsageDataService.shared.stateStream {
        guard let self, !Task.isCancelled else { break }
        // Already on @MainActor, no need for MainActor.run wrapper
        isInitializing = state.isInitializing
        usageLimits = state.usageLimits
        lastUpdated = state.lastUpdated
        error = state.error
        tokenSource = state.tokenSource
        hasValidToken = state.hasValidToken
        preferredTokenSource = state.preferredTokenSource
      }
    }
  }

  // MARK: - Public Methods

  func refresh() async {
    isLoading = true
    await UsageDataService.shared.refresh()
    isLoading = false
  }

  func checkTokenAvailability() {
    // Token availability is managed by UsageDataService and synced via stream.
    // This triggers a refresh to update the state.
    Task {
      await UsageDataService.shared.refresh()
    }
  }

  /// Saves the manual token after a brief delay to avoid saving on every keystroke.
  func saveManualTokenDebounced(_ token: String) {
    saveTask?.cancel()
    saveTask = Task {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }

      do {
        if token.isEmpty {
          try await UsageDataService.shared.clearManualToken()
        } else {
          try await UsageDataService.shared.saveManualToken(token)
        }
      } catch {
        // Token save errors are non-fatal, logged by the service
      }
    }
  }

  /// Validates the manually-entered token against the API.
  func validateManualToken() async {
    guard !manualTokenInput.isEmpty else { return }

    isValidatingToken = true
    tokenValidationResult = nil

    let isValid = await UsageDataService.shared.validateToken(manualTokenInput)

    tokenValidationResult = isValid ? .valid : .invalid
    isValidatingToken = false
  }
}
