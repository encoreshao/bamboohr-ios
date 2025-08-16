//
//  GradientButtonStyles.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

// MARK: - Primary Gradient Button Style
struct PrimaryGradientButtonStyle: ButtonStyle {
    let isDisabled: Bool

    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: isDisabled ?
                                [Color.gray.opacity(0.6), Color.gray.opacity(0.4)] :
                                [Color.blue, Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isDisabled ? .clear : .blue.opacity(0.3),
                        radius: configuration.isPressed ? 4 : 8,
                        x: 0,
                        y: configuration.isPressed ? 2 : 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Gradient Button Style
struct SecondaryGradientButtonStyle: ButtonStyle {
    let isDisabled: Bool

    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isDisabled ? .gray : .blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: isDisabled ?
                                [Color(.systemGray6), Color(.systemGray5)] :
                                [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: isDisabled ?
                                        [Color.gray.opacity(0.3), Color.gray.opacity(0.2)] :
                                        [Color.blue.opacity(0.4), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Destructive Gradient Button Style
struct DestructiveGradientButtonStyle: ButtonStyle {
    let isDisabled: Bool

    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: isDisabled ?
                                [Color.gray.opacity(0.6), Color.gray.opacity(0.4)] :
                                [Color.red, Color.red.opacity(0.8), Color.orange.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isDisabled ? .clear : .red.opacity(0.3),
                        radius: configuration.isPressed ? 4 : 8,
                        x: 0,
                        y: configuration.isPressed ? 2 : 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Gradient Button Style (for smaller buttons)
struct CompactGradientButtonStyle: ButtonStyle {
    let color: Color
    let isDisabled: Bool

    init(color: Color = .blue, isDisabled: Bool = false) {
        self.color = color
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isDisabled ? .gray : .white)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: isDisabled ?
                                [Color.gray.opacity(0.4), Color.gray.opacity(0.3)] :
                                [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isDisabled ? .clear : color.opacity(0.3),
                        radius: configuration.isPressed ? 2 : 4,
                        x: 0,
                        y: configuration.isPressed ? 1 : 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Navigation Gradient Button Style (for toolbar buttons)
struct NavigationGradientButtonStyle: ButtonStyle {
    let color: Color

    init(color: Color = .blue) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: color.opacity(0.3),
                        radius: configuration.isPressed ? 2 : 4,
                        x: 0,
                        y: configuration.isPressed ? 1 : 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Action Card Gradient Style (for cards that are buttons)
struct ActionCardGradientStyle: ButtonStyle {
    let color: Color

    init(color: Color = .blue) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.05), color.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [color.opacity(0.3), color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: color.opacity(0.1),
                        radius: configuration.isPressed ? 2 : 6,
                        x: 0,
                        y: configuration.isPressed ? 1 : 3
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions
extension View {
    func primaryGradientButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(PrimaryGradientButtonStyle(isDisabled: isDisabled))
    }

    func secondaryGradientButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(SecondaryGradientButtonStyle(isDisabled: isDisabled))
    }

    func destructiveGradientButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(DestructiveGradientButtonStyle(isDisabled: isDisabled))
    }

    func compactGradientButtonStyle(color: Color = .blue, isDisabled: Bool = false) -> some View {
        self.buttonStyle(CompactGradientButtonStyle(color: color, isDisabled: isDisabled))
    }

    func navigationGradientButtonStyle(color: Color = .blue) -> some View {
        self.buttonStyle(NavigationGradientButtonStyle(color: color))
    }

    func actionCardGradientStyle(color: Color = .blue) -> some View {
        self.buttonStyle(ActionCardGradientStyle(color: color))
    }
}
