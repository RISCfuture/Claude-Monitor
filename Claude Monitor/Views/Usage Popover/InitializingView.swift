//
//  InitializingView.swift
//  Claude Monitor
//
//  Created by Tim Morgan on 12/15/25.
//

import SwiftUI

/// A view displayed while the app is initializing and loading keychain data.
///
/// `InitializingView` is shown during app startup while the keychain is being
/// accessed. This prevents the UI from appearing unresponsive during potentially
/// slow keychain operations.
struct InitializingView: View {
  var body: some View {
    VStack(spacing: 12) {
      ProgressView()
        .controlSize(.regular)
        .accessibilityHidden(true)

      Text("Loading…")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
  }
}

#Preview {
  InitializingView()
    .frame(width: 320)
}
