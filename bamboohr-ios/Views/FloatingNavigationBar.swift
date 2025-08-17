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
                // Creative glassmorphism background
                ZStack {
                    // Base glass effect
                    RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)

                    // Gradient overlay for depth
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05),
                                    Color.black.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Subtle border with gradient
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .frame(maxHeight: 60) // Constrain maximum height
        .frame(maxWidth: 350) // Constrain maximum width to prevent expansion
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                isAnimating = true
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

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background for selected state
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tab.color.opacity(0.15),
                                    tab.color.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(tab.color.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: tab.color.opacity(0.2), radius: 8, x: 0, y: 4)
                        .scaleEffect(1.05)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 1.1).combined(with: .opacity)
                        ))
                }

                VStack(spacing: 1) {
                    // Enhanced icon with glow effect
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
                            .scaleEffect(isSelected ? 1.0 : 1.0) // Additional scale for selected state
                            .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: isSelected)
                            .animation(.easeInOut(duration: 0.2), value: hoverScale)
                    }

                    // Dynamic text with enhanced styling
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

