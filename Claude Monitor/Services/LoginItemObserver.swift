//
//  LoginItemObserver.swift
//  Claude Monitor
//
//  Created by Tim Morgan on 12/11/25.
//

import ServiceManagement

/// Observes changes to the app's login item status by polling.
///
/// Since `SMAppService.status` doesn't reliably notify via KVO for external
/// changes (e.g., user toggling in System Settings), this class polls the
/// status every 0.5 seconds to keep the UI in sync.
@MainActor
@Observable
final class LoginItemObserver {
  /// Whether the app is running from a location where login items work.
  private static var canUseLoginItems: Bool {
    let bundlePath = Bundle.main.bundlePath
    return bundlePath.hasPrefix("/Applications")
      || bundlePath.hasPrefix(NSHomeDirectory() + "/Applications")
  }

  var isEnabled: Bool {
    didSet {
      guard Self.canUseLoginItems, isEnabled != (SMAppService.mainApp.status == .enabled) else {
        return
      }
      try? isEnabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
    }
  }

  private var pollingTask: Task<Void, Never>?

  init() {
    isEnabled = Self.canUseLoginItems && SMAppService.mainApp.status == .enabled
    startPolling()
  }

  private func startPolling() {
    guard Self.canUseLoginItems else { return }

    pollingTask = Task { @MainActor [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(500))
        guard let self else { return }
        let currentStatus = SMAppService.mainApp.status == .enabled
        if isEnabled != currentStatus {
          isEnabled = currentStatus
        }
      }
    }
  }
}
