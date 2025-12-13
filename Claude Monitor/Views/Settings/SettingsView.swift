//
//  SettingsView.swift
//  Claude Monitor
//
//  Created by Tim Morgan on 12/3/25.
//

import GitHubUpdateChecker
import SwiftUI

/// The main settings view for configuring API tokens.
///
/// `SettingsView` allows users to choose between two token sources:
/// - **Claude Code** — Automatically uses the OAuth token from Claude Code
/// - **Manual** — Allows users to paste a token directly
///
/// The view displays appropriate warnings when Claude Code is selected but
/// no token is found, and provides help text explaining how to obtain tokens.
///
/// ## View Hierarchy
/// - Token source picker
/// - ``ManualTokenView`` (when manual source selected)
/// - Warning label (when Claude Code unavailable)
/// - ``SettingsHelpView``
struct SettingsView: View {
  @Environment(\.viewModel)
  private var viewModel

  @Environment(\.updateChecker)
  private var updateChecker

  @State private var loginItemObserver = LoginItemObserver()

  var body: some View {
    @Bindable var viewModel = viewModel
    @Bindable var loginItemObserver = loginItemObserver

    Form {
      Section {
        Picker("Token Source", selection: $viewModel.preferredTokenSource) {
          Text("Claude Code")
            .tag(TokenSource.claudeCode)
          Text("Manual")
            .tag(TokenSource.manual)
        }
        .pickerStyle(.menu)

        if viewModel.preferredTokenSource == .manual {
          ManualTokenView()
        }

        if !viewModel.isClaudeCodeTokenAvailable && viewModel.preferredTokenSource == .claudeCode {
          Label(
            "Claude Code token not found. Install Claude Code or switch to Manual.",
            systemImage: "exclamationmark.triangle.fill"
          )
          .foregroundStyle(.orange)
          .font(.caption)
        }

        SettingsHelpView()
      }
      Section {
        Toggle("Launch at Login", isOn: $loginItemObserver.isEnabled)

        Picker("Check for Updates", selection: Bindable(UpdatePreferences.shared).updateCadence) {
          Text("Never").tag(UpdateCadence.never)
          Text("Hourly").tag(UpdateCadence.hourly)
          Text("Daily").tag(UpdateCadence.daily)
          Text("Weekly").tag(UpdateCadence.weekly)
        }
        .pickerStyle(.menu)

        Button("Check Now") {
          Task {
            await updateChecker?.checkForUpdatesAndShowUI()
          }
        }
      }
    }
    .formStyle(.grouped)
    .frame(width: 480)
    .fixedSize(horizontal: false, vertical: true)
    .onAppear {
      viewModel.checkTokenAvailability()
    }
  }
}

#Preview {
  SettingsView()
    .viewModel(UsageViewModel())
}
