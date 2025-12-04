//
//  Claude_MonitorApp.swift
//  Claude Monitor
//
//  Created by Tim Morgan on 12/3/25.
//

import AppKit
import Sentry
import SwiftUI

/// The application delegate that handles app lifecycle events.
///
/// This delegate starts the `UsageDataService` when the app finishes launching,
/// ensuring data is fetched and background refresh begins immediately.
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    Task {
      await UsageDataService.shared.start()
    }
  }
}

/// The main entry point for Claude Monitor.
///
/// Claude Monitor is a macOS menu bar application that displays Claude API
/// usage limits. It provides two scenes:
///
/// 1. **Menu Bar Extra** — A popover showing current usage data
/// 2. **Settings** — A window for configuring token sources
///
/// The app uses `MenuBarExtra` with `.window` style to display the usage
/// popover when the menu bar icon is clicked.
///
/// ## Architecture
/// - `UsageDataService` (actor singleton) owns all business logic and state
/// - `UsageViewModel` subscribes to state changes via `AsyncStream`
/// - `AppDelegate` starts the service at app launch
@main
struct Claude_MonitorApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self)
  private var appDelegate

  /// The shared view model used across all views.
  @State private var viewModel = UsageViewModel()

  var body: some Scene {
    MenuBarExtra {
      ContentView()
        .viewModel(viewModel)
    } label: {
      MenuBarIconView()
        .viewModel(viewModel)
    }
    .menuBarExtraStyle(.window)

    Settings {
      SettingsView()
        .viewModel(viewModel)
        .onAppear {
          NSApp.activate(ignoringOtherApps: true)
        }
    }
  }

  init() {
    SentrySDK.start { options in
      options.dsn =
        "https://2c46a025d464b0b7eea0ef443c109d20@o4510156629475328.ingest.us.sentry.io/4510477814398976"
      options.sendDefaultPii = true
      options.tracesSampleRate = 1.0

      options.configureProfiling = {
        $0.sessionSampleRate = 1.0
        $0.lifecycle = .trace
      }

      #if DEBUG
        // Discard all events in debug builds
        options.beforeSend = { _ in nil }
      #endif
    }
  }
}
