//
//  ErrorStateViews.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

// MARK: - Unified Loading View
struct UnifiedLoadingView: View {
    let message: String
    let subMessage: String
    let color: Color

    init(message: String, subMessage: String = "Please wait...", color: Color = .blue) {
        self.message = message
        self.subMessage = subMessage
        self.color = color
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                // Loading animation
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.8)
                        .tint(color)

                    // Animated dots
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(color)
                                .frame(width: 6, height: 6)
                                .opacity(0.3)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: true
                                )
                        }
                    }
                }

                VStack(spacing: 8) {
                    Text(message)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(subMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Unified Error View
struct UnifiedErrorView: View {
    let title: String
    let message: String
    let buttonColor: Color
    let action: () -> Void

    init(title: String = "Loading failed", message: String, buttonColor: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.buttonColor = buttonColor
        self.action = action
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 32) {
                // Error illustration
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.1), .red.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "wifi.slash")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 12) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(message)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .padding(.horizontal, 20)
                    }
                }

                // Retry button with better styling
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        action()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Retry")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [buttonColor, buttonColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: true)
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview("Loading View") {
    UnifiedLoadingView(
        message: "Loading employees...",
        subMessage: "Please wait...",
        color: .green
    )
}

#Preview("Error View") {
    UnifiedErrorView(
        title: "Loading failed",
        message: "Unable to load data. Please check your connection and try again.",
        buttonColor: .blue
    ) {
        print("Retry tapped")
    }
}