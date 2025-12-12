//
//  ViewModelKey.swift
//  Claude Monitor
//
//  Created by Tim Morgan on 12/3/25.
//

import GitHubUpdateChecker
import SwiftUI

// MARK: - Environment Key

/// Environment key for providing the view model.
///
/// Uses the concrete `UsageViewModel` type to ensure SwiftUI's observation
/// system works correctly with the `@Observable` macro.
private struct ViewModelKey: @preconcurrency EnvironmentKey {
  @MainActor static let defaultValue = UsageViewModel()
}

extension EnvironmentValues {
  /// The view model for Claude status.
  var viewModel: UsageViewModel {
    get { self[ViewModelKey.self] }
    set { self[ViewModelKey.self] = newValue }
  }
}

extension View {
  /// Sets the view model in the environment.
  func viewModel(_ viewModel: UsageViewModel) -> some View {
    environment(\.viewModel, viewModel)
  }
}

// MARK: - Update Checker Key

/// Environment key for providing the update checker.
private struct UpdateCheckerKey: EnvironmentKey {
  static let defaultValue: GitHubUpdateChecker? = nil
}

extension EnvironmentValues {
  /// The update checker for checking GitHub releases.
  var updateChecker: GitHubUpdateChecker? {
    get { self[UpdateCheckerKey.self] }
    set { self[UpdateCheckerKey.self] = newValue }
  }
}

extension View {
  /// Sets the update checker in the environment.
  func updateChecker(_ checker: GitHubUpdateChecker) -> some View {
    environment(\.updateChecker, checker)
  }
}
