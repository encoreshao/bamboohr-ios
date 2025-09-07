//
//  FloatingNavigationBar.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct FloatingNavigationBar: View {
    @Binding var selectedTab: Int
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isAnimating = false
    @State private var morphingEffect: CGFloat = 0
    @State private var ripplePhase: CGFloat = 0
    @State private var colorShift: Double = 0
    @State private var breathingScale: CGFloat = 1.0

    private let tabs = [
        TabItem(id: 0, icon: "house", activeIcon: "house.fill", title: "Home", color: .blue, style: .primary),
        TabItem(id: 1, icon: "clock", activeIcon: "clock.fill", title: "Time", color: .purple, style: .accent),
        TabItem(id: 2, icon: "calendar", activeIcon: "calendar.badge.clock", title: "Leave", color: .orange, style: .warm),
        TabItem(id: 3, icon: "person.crop.circle", activeIcon: "person.crop.circle.fill", title: "People", color: .green, style: .fresh),
        TabItem(id: 4, icon: "gear", activeIcon: "gearshape.fill", title: "Settings", color: .gray, style: .neutral)
    ]

    var body: some View {
        // Creative floating container with glassmorphism effect
        HStack(spacing: 8) {
                ForEach(tabs, id: \.id) { tab in
                    CreativeTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab.id,
                        action: {
                            // Enhanced haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: selectedTab == tab.id ? .medium : .light)
                            impactFeedback.impactOccurred()

                            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                                selectedTab = tab.id
                            }
                        }
                    )
                }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
                // Enhanced creative glassmorphism background
                ZStack {
                    // Morphing ripple effects
                    ForEach(0..<2, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 18 + CGFloat(index) * 2)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.3 - Double(index) * 0.1),
                                        Color.purple.opacity(0.2 - Double(index) * 0.05),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .scaleEffect(1.0 + ripplePhase * 0.05 + CGFloat(index) * 0.02)
                            .opacity(1.0 - ripplePhase * 0.3)
                    }

                    // Base glass effect with morphing
                    RoundedRectangle(cornerRadius: 18 + morphingEffect)
                        .fill(.ultraThinMaterial)
                        .opacity(0.85)
                        .scaleEffect(breathingScale)

                    // Dynamic gradient overlay
                    RoundedRectangle(cornerRadius: 18 + morphingEffect)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.3 + sin(colorShift) * 0.1),
                                    Color.blue.opacity(0.1 + cos(colorShift * 1.2) * 0.05),
                                    Color.purple.opacity(0.05 + sin(colorShift * 0.8) * 0.03),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.5 + sin(colorShift) * 0.1, y: 0.5 + cos(colorShift) * 0.1),
                                startRadius: 10,
                                endRadius: 100
                            )
                        )
                        .scaleEffect(breathingScale)

                    // Enhanced border with dynamic colors
                    RoundedRectangle(cornerRadius: 18 + morphingEffect)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4 + sin(colorShift) * 0.1),
                                    Color.blue.opacity(0.2 + cos(colorShift) * 0.1),
                                    Color.purple.opacity(0.1 + sin(colorShift * 1.5) * 0.05),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        .scaleEffect(breathingScale)
                }
                .shadow(color: .blue.opacity(0.15), radius: 25, x: 0, y: 12)
                .shadow(color: .purple.opacity(0.1), radius: 15, x: 0, y: 8)
                .shadow(color: .black.opacity(0.08), radius: 30, x: 0, y: 15)
            )
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .frame(maxHeight: 60) // Constrain maximum height
        .frame(maxWidth: 350) // Constrain maximum width to prevent expansion
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                isAnimating = true
            }

            // Start continuous morphing effects
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                morphingEffect = 3.0
            }

            // Start ripple animation
            withAnimation(.easeOut(duration: 2.0).repeatForever()) {
                ripplePhase = 1.0
            }

            // Start color shifting
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                colorShift = .pi * 2
            }

            // Start breathing effect
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathingScale = 1.03
            }
        }
    }


}

struct CreativeTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    @State private var hoverScale: CGFloat = 1.0
    @State private var pulsePhase: CGFloat = 0
    @State private var glowIntensity: Double = 0
    @State private var rotationAngle: Double = 0

    private var selectedBackground: some View {
        ZStack {
            // Pulsing glow effect
            RoundedRectangle(cornerRadius: 12)
                .fill(tab.color.opacity(0.3))
                .blur(radius: 8)
                .scaleEffect(1.2 + pulsePhase * 0.1)
                .opacity(glowIntensity * 0.6)

            // Main background
            RoundedRectangle(cornerRadius: 12)
                .fill(tab.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(tab.color.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: tab.color.opacity(0.3), radius: 12, x: 0, y: 6)
                .scaleEffect(1.05 + pulsePhase * 0.02)
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.7).combined(with: .opacity),
            removal: .scale(scale: 1.2).combined(with: .opacity)
        ))
    }

    private var iconView: some View {
        ZStack {
            // Icon glow for selected state
            if isSelected {
                Image(systemName: tab.activeIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tab.color)
                    .opacity(0.3)
                    .blur(radius: 8)
                    .scaleEffect(1.5)
            }

            // Main icon
            Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                .font(.system(size: isSelected ? 20 : 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? tab.color : tab.color.opacity(0.6))
                .scaleEffect(hoverScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: isSelected)
                .animation(.easeInOut(duration: 0.2), value: hoverScale)
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background for selected state
                if isSelected {
                    selectedBackground
                }

                VStack(spacing: 1) {
                    // Icon with glow effect
                    iconView

                    // Dynamic text
                    if !isSelected {
                        Text(getLocalizedTitle(tab.title))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(tab.color.opacity(0.7))
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
            }
            .frame(minWidth: 40, minHeight: 40)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(CreativeTabButtonStyle(isPressed: $isPressed))
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoverScale = hovering ? 1.1 : 1.0
            }
        }
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .onAppear {
            if isSelected {
                // Start pulsing animation for selected tab
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulsePhase = 1.0
                }

                // Start glow animation
                withAnimation(.easeInOut(duration: 0.8)) {
                    glowIntensity = 1.0
                }

                // Start rotation animation
                withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                    rotationAngle = .pi * 2
                }
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                // Animate when becoming selected
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulsePhase = 1.0
                }

                withAnimation(.easeInOut(duration: 0.8)) {
                    glowIntensity = 1.0
                }

                withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                    rotationAngle = .pi * 2
                }
            } else {
                // Reset when deselected
                withAnimation(.easeOut(duration: 0.5)) {
                    pulsePhase = 0
                    glowIntensity = 0
                }
            }
        }
    }

    private func getLocalizedTitle(_ title: String) -> String {
        let localizationManager = LocalizationManager.shared
        switch title {
        case "Home":
            return localizationManager.localized(.tabHome)
        case "Time":
            return localizationManager.localized(.tabTime)
        case "Leave":
            return localizationManager.localized(.tabLeave)
        case "People":
            return localizationManager.localized(.tabPeople)
        case "Settings":
            return localizationManager.localized(.tabSettings)
        default:
            return title
        }
    }
}

struct CreativeTabButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = pressed
                }
            }
    }
}

// MARK: - Tab Helper Extensions
extension FloatingNavigationBar {
    static func getTabInfo(for tabId: Int) -> TabItem? {
        let tabs = [
            TabItem(id: 0, icon: "house", activeIcon: "house.fill", title: "Home", color: .blue, style: .primary),
            TabItem(id: 1, icon: "clock", activeIcon: "clock.fill", title: "Time", color: .purple, style: .accent),
            TabItem(id: 2, icon: "calendar", activeIcon: "calendar.badge.clock", title: "Leave", color: .orange, style: .warm),
            TabItem(id: 3, icon: "person.crop.circle", activeIcon: "person.crop.circle.fill", title: "People", color: .green, style: .fresh),
            TabItem(id: 4, icon: "gear", activeIcon: "gearshape.fill", title: "Settings", color: .gray, style: .neutral)
        ]
        return tabs.first { $0.id == tabId }
    }
}

struct TabItem {
    let id: Int
    let icon: String
    let activeIcon: String
    let title: String
    let color: Color
    let style: TabStyle
}

enum TabStyle {
    case primary, accent, warm, fresh, neutral

    var gradient: [Color] {
        switch self {
        case .primary:
            return [.blue, .blue.opacity(0.7), .cyan.opacity(0.5)]
        case .accent:
            return [.purple, .purple.opacity(0.7), .pink.opacity(0.5)]
        case .warm:
            return [.orange, .orange.opacity(0.7), .yellow.opacity(0.5)]
        case .fresh:
            return [.green, .green.opacity(0.7), .mint.opacity(0.5)]
        case .neutral:
            return [.gray, .gray.opacity(0.7), .secondary.opacity(0.5)]
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary: return .blue
        case .accent: return .purple
        case .warm: return .orange
        case .fresh: return .green
        case .neutral: return .gray
        }
    }
}

// MARK: - Floating Navigation Container
struct FloatingTabView<Content: View>: View {
    @Binding var selectedTab: Int
    let content: Content
    @State private var keyboardHeight: CGFloat = 0
    @State private var isNavbarVisible: Bool = true

    init(selectedTab: Binding<Int>, @ViewBuilder content: () -> Content) {
        self._selectedTab = selectedTab
        self.content = content()
    }

        var body: some View {
        ZStack {
            // Main content area
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 70) // Space for floating navigation bar

            // Floating navigation at the bottom - Always visible
            if isNavbarVisible {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingNavigationBar(selectedTab: $selectedTab)
                            .offset(y: keyboardHeight > 0 ? min(-keyboardHeight + 60, -20) : 0)
                            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
                            .zIndex(999) // Ensure navbar stays on top
                        Spacer()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            withAnimation(.easeInOut(duration: 0.3)) {
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
                // Ensure navbar stays visible when keyboard appears
                isNavbarVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
                // Ensure navbar stays visible when keyboard disappears
                isNavbarVisible = true
            }
        }
        .onAppear {
            // Ensure navbar is visible on appear
            isNavbarVisible = true
        }
    }
}

#Preview {
    FloatingNavigationBar(selectedTab: .constant(0))
}

