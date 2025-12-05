//
//  ShadedProgressView.swift
//  Claude Monitor Widget
//

import SwiftUI

/// A custom progress bar with a solid fill and rounded corners.
struct ShadedProgressView: View {
  let value: Double
  let tint: Color

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 3)
          .fill(Color.secondary.opacity(0.2))

        RoundedRectangle(cornerRadius: 3)
          .fill(tint)
          .frame(width: geometry.size.width * min(max(value, 0), 1))
      }
    }
    .frame(height: 6)
  }

  init(value: Double, tint: Color = .accentColor) {
    self.value = value
    self.tint = tint
  }
}
