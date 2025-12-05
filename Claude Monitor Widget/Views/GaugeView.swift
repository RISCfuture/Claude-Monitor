//
//  GaugeView.swift
//  Claude Monitor Widget
//

import SwiftUI

/// A circular gauge view showing utilization with the Claude logo in the center.
struct GaugeView: View {
  let utilization: Double
  let size: CGFloat

  private var clampedUtilization: Double {
    max(0, min(1, utilization))
  }

  var body: some View {
    ZStack {
      // Background track (270° arc, open at bottom)
      Circle()
        .trim(from: 0, to: 0.75)
        .stroke(
          Color.secondary.opacity(0.2),
          style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
        )
        .rotationEffect(.degrees(135))

      // Filled arc based on utilization
      Circle()
        .trim(from: 0, to: 0.75 * clampedUtilization)
        .stroke(
          gaugeColor,
          style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
        )
        .rotationEffect(.degrees(135))

      // Claude logo in center
      ClaudeLogoView()
        .frame(width: size * 0.55, height: size * 0.55)

      // Percentage below
      VStack {
        Spacer()
        Text("\(Int(clampedUtilization * 100))%")
          .font(.system(size: size * 0.15, weight: .medium, design: .rounded))
          .foregroundStyle(.secondary)
      }
      .padding(.bottom, size * 0.05)
    }
    .frame(width: size, height: size)
  }

  private var gaugeColor: Color {
    switch clampedUtilization {
      case 0..<0.5: .blue
      case 0.5..<0.8: .yellow
      case 0.8..<0.95: .orange
      default: .red
    }
  }
}

/// The Claude "C" logo as a SwiftUI shape.
struct ClaudeLogoView: View {
  var body: some View {
    GeometryReader { geometry in
      let scale = min(geometry.size.width, geometry.size.height) / 24

      Path { path in
        // Simplified Claude logo path (star shape)
        let points: [(Double, Double)] = [
          (7.55, 14.25), (10.11, 12.81), (10.15, 12.69), (10.11, 12.62),
          (9.98, 12.62), (9.56, 12.59), (8.09, 12.56), (6.83, 12.50),
          (5.60, 12.44), (5.29, 12.37), (5.0, 11.99), (5.03, 11.80),
          (5.29, 11.62), (5.66, 11.66), (6.48, 11.71), (7.72, 11.80),
          (8.61, 11.85), (9.94, 11.99), (10.15, 11.99), (10.18, 11.90),
          (10.11, 11.85), (10.05, 11.80), (8.78, 10.93), (7.39, 10.02),
          (6.67, 9.49), (6.28, 9.23), (6.08, 8.98), (5.99, 8.43),
          (6.35, 8.04), (6.83, 8.07), (6.95, 8.10), (7.43, 8.48),
          (8.47, 9.27), (9.82, 10.27), (10.01, 10.43), (10.09, 10.38),
          (10.10, 10.34), (10.01, 10.19), (9.28, 8.86), (8.50, 7.51),
          (8.15, 6.96), (8.06, 6.62), (8.0, 6.23), (8.40, 5.68),
          (8.63, 5.60), (9.17, 5.68), (9.40, 5.87), (9.73, 6.64),
          (10.27, 7.85), (11.12, 9.49), (11.36, 9.98), (11.50, 10.43),
          (11.54, 10.56), (11.63, 10.56), (11.63, 10.49), (11.70, 9.56),
          (11.83, 8.43), (11.95, 6.96), (11.99, 6.55), (12.20, 6.06),
          (12.60, 5.79), (12.92, 5.94), (13.18, 6.32), (13.14, 6.56),
          (12.99, 7.56), (12.69, 9.13), (12.49, 10.19), (12.60, 10.19),
          (12.73, 10.05), (13.27, 9.35), (14.16, 8.23), (14.56, 7.78),
          (15.02, 7.29), (15.31, 7.06), (15.87, 7.06), (16.29, 7.67),
          (16.10, 8.30), (15.53, 9.03), (15.05, 9.65), (14.36, 10.57),
          (13.94, 11.31), (13.98, 11.37), (14.08, 11.36), (15.62, 11.03),
          (16.46, 10.88), (17.46, 10.71), (17.91, 10.92), (17.96, 11.13),
          (17.78, 11.57), (16.71, 11.83), (15.46, 12.08), (13.60, 12.52),
          (13.58, 12.54), (13.60, 12.57), (14.44, 12.65), (14.80, 12.67),
          (15.68, 12.67), (17.32, 12.79), (17.74, 13.08), (18.0, 13.42),
          (17.96, 13.69), (17.30, 14.02), (16.41, 13.81), (14.34, 13.32),
          (13.63, 13.14), (13.53, 13.14), (13.53, 13.20), (14.12, 13.78),
          (15.21, 14.76), (16.57, 16.02), (16.63, 16.33), (16.46, 16.58),
          (16.28, 16.55), (15.08, 15.65), (14.62, 15.25), (13.58, 14.37),
          (13.51, 14.37), (13.51, 14.46), (13.75, 14.82), (15.02, 16.72),
          (15.08, 17.31), (14.99, 17.50), (14.66, 17.61), (14.30, 17.55),
          (13.56, 16.51), (12.79, 15.33), (12.17, 14.28), (12.10, 14.32),
          (11.73, 18.25), (11.56, 18.45), (11.16, 18.60), (10.84, 18.35),
          (10.66, 17.95), (10.84, 17.15), (11.05, 16.11), (11.22, 15.28),
          (11.37, 14.25), (11.46, 13.91), (11.46, 13.88), (11.38, 13.89),
          (10.61, 14.96), (9.42, 16.55), (8.49, 17.55), (8.26, 17.64),
          (7.88, 17.44), (7.91, 17.08), (8.13, 16.76), (9.42, 15.12),
          (10.20, 14.10), (10.71, 13.51), (10.70, 13.43), (10.67, 13.43),
          (7.24, 15.66), (6.63, 15.74), (6.36, 15.49), (6.39, 15.08),
          (6.52, 14.95), (7.55, 14.24)
        ]

        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        let offsetX = 11.5 * scale
        let offsetY = 12.1 * scale

        for (index, point) in points.enumerated() {
          let x = centerX + (CGFloat(point.0) * scale - offsetX)
          let y = centerY - (CGFloat(point.1) * scale - offsetY)

          if index == 0 {
            path.move(to: CGPoint(x: x, y: y))
          } else {
            path.addLine(to: CGPoint(x: x, y: y))
          }
        }
        path.closeSubpath()
      }
      .fill(Color.primary)
    }
  }
}

#Preview {
  HStack(spacing: 20) {
    GaugeView(utilization: 0.25, size: 80)
    GaugeView(utilization: 0.67, size: 80)
    GaugeView(utilization: 0.92, size: 80)
  }
  .padding()
}
