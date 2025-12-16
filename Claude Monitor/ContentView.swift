//
//  ContentView.swift
//  Claude Monitor
//
//  Created by Tim Morgan on 12/3/25.
//

import SwiftUI

// MARK: - Content View

/// The main content view for the menu bar popover.
///
/// `ContentView` is the root view displayed when the user clicks the menu bar
/// icon. It composes several child views to display usage data, handle errors,
/// and provide actions.
///
/// ## View Hierarchy
/// - ``UsageHeaderView`` — Title and refresh button
/// - ``UsageContentView`` or ``NoTokenView`` — Main content area
/// - ``FooterView`` — Token source and last updated time
/// - ``ActionButtonsView`` — Settings and Quit buttons
///
/// ## Environment
/// The view expects a view model to be provided via `.viewModel(_:)` modifier.
/// Background refresh is handled by ``BackgroundRefreshService`` at the app level.
///
/// ## Lifecycle
/// The view triggers an immediate refresh when it appears (popover opened) and
/// starts a fast auto-refresh timer for responsive UI updates while visible.
struct ContentView: View {

  /// Minimum time between refreshes when opening the popover.
  private static let refreshCooldown: TimeInterval = 20

  @Environment(\.viewModel)
  private var viewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      UsageHeaderView(isLoading: viewModel.isLoading) {
        await viewModel.refresh()
      }

      Divider()

      if viewModel.isInitializing {
        InitializingView()
      } else if viewModel.hasValidToken {
        UsageContentView(
          usageLimits: viewModel.usageLimits,
          error: viewModel.error,
          isLoading: viewModel.isLoading,
          onRetry: { await viewModel.refresh() }
        )
      } else {
        NoTokenView()
      }

      if !viewModel.isLoading || !viewModel.usageLimits.isEmpty {
        FooterView(
          tokenSourceName: viewModel.tokenSource?.localizedName,
          lastUpdated: viewModel.lastUpdated
        )

        Divider()
      }

      ActionButtonsView(
        showSettingsButton: viewModel.hasValidToken,
        onQuit: { NSApplication.shared.terminate(nil) }
      )
    }
    .frame(width: 320)
    .task {
      // Only refresh if data is stale (background refresh handles periodic updates)
      let isStale =
        viewModel.lastUpdated
        .map { Date().timeIntervalSince($0) > Self.refreshCooldown } ?? true
      if isStale {
        await viewModel.refresh()
      }
    }
  }
}

extension TokenSource {
  var localizedName: String {
    switch self {
      case .claudeCode:
        return String(localized: "Claude Code")
      case .manual:
        return String(localized: "Settings")
    }
  }
}

#Preview {
  ContentView()
}
