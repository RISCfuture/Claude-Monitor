//
//  MockUsageViewModel.swift
//  Claude Monitor
//
//  Created by Tim Morgan on 12/3/25.
//

import Foundation
import Observation

/// A mock view model for SwiftUI previews and testing.
///
/// `MockUsageViewModel` implements ``UsageViewModelProtocol``
/// with no-op methods, allowing views to be previewed with pre-configured state
/// without making real API calls.
///
/// ## Static Factory Properties
/// Use the static properties to get pre-configured instances for common states:
/// - ``loading`` — Shows loading spinner
/// - ``withUsageData`` — Shows normal usage data
/// - ``highUsage`` — Shows high usage with warning colors
/// - ``noToken`` — Shows the no-token prompt
/// - ``error`` — Shows an authentication error
/// - ``networkError`` — Shows a network error
///
/// ## Example
/// ```swift
/// #Preview("With Usage Data") {
///   ContentView(viewModel: MockUsageViewModel.withUsageData)
/// }
/// ```
@Observable
@MainActor
final class MockUsageViewModel: UsageViewModelProtocol {
  // MARK: - Usage State

  var isInitializing = false
  var usageLimits: [UsageLimit] = []
  var isLoading = false
  var error: Error?
  var lastUpdated: Date?
  var tokenSource: TokenSource?
  var hasValidToken = false

  // MARK: - Settings State

  var preferredTokenSource: TokenSource = .claudeCode
  var manualTokenInput = ""
  var isValidatingToken = false
  var tokenValidationResult: TokenValidationResult?
  var isClaudeCodeTokenAvailable = true

  // MARK: - Methods (No-ops for previews)

  func refresh() {}
  func checkTokenAvailability() {}
  func saveManualTokenDebounced(_: String) {}
  func validateManualToken() {}
}

// MARK: - Preview Helpers

extension MockUsageViewModel {
  /// A mock in the initializing state (loading keychain).
  static var initializing: MockUsageViewModel {
    let vm = MockUsageViewModel()
    vm.isInitializing = true
    return vm
  }

  /// A mock in the loading state with no data yet.
  static var loading: MockUsageViewModel {
    let vm = MockUsageViewModel()
    vm.isLoading = true
    vm.hasValidToken = true
    return vm
  }

  /// A mock with typical usage data displayed.
  static var withUsageData: MockUsageViewModel {
    let vm = MockUsageViewModel()
    vm.hasValidToken = true
    vm.tokenSource = .claudeCode
    vm.lastUpdated = .now
    vm.usageLimits = [
      UsageLimit(
        id: "five_hour",
        title: "Current session",
        utilization: 0.35,
        resetsAt: .now.addingTimeInterval(3600 * 2)
      ),
      UsageLimit(
        id: "seven_day",
        title: "All models",
        utilization: 0.72,
        resetsAt: .now.addingTimeInterval(86400 * 3)
      )
    ]
    return vm
  }

  /// A mock with high usage showing warning/danger colors.
  static var highUsage: MockUsageViewModel {
    let vm = MockUsageViewModel()
    vm.hasValidToken = true
    vm.tokenSource = .claudeCode
    vm.lastUpdated = .now
    vm.usageLimits = [
      UsageLimit(
        id: "five_hour",
        title: "Current session",
        utilization: 0.92,
        resetsAt: .now.addingTimeInterval(1800)
      ),
      UsageLimit(
        id: "seven_day",
        title: "All models",
        utilization: 0.85,
        resetsAt: .now.addingTimeInterval(86400 * 2)
      ),
      UsageLimit(
        id: "seven_day_opus",
        title: "Opus only",
        utilization: 0.98,
        resetsAt: .now.addingTimeInterval(86400 * 2)
      )
    ]
    return vm
  }

  /// A mock with no token available, showing the setup prompt.
  static var noToken: MockUsageViewModel {
    let vm = MockUsageViewModel()
    vm.hasValidToken = false
    vm.isClaudeCodeTokenAvailable = false
    return vm
  }

  /// A mock showing an authentication error (401).
  static var error: MockUsageViewModel {
    let vm = MockUsageViewModel()
    vm.hasValidToken = true
    vm.error = APIError.httpError(statusCode: 401, message: nil)
    return vm
  }

  /// A mock showing a network connectivity error.
  static var networkError: MockUsageViewModel {
    let vm = MockUsageViewModel()
    vm.hasValidToken = true
    vm.error = APIError.networkError(URLError(.notConnectedToInternet))
    return vm
  }
}
