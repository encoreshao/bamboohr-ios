//
//  MicroInteractions.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

// MARK: - Enhanced Button Styles with Micro-interactions

struct PulseButtonStyle: ButtonStyle {
    let color: Color
    let intensity: CGFloat

    init(color: Color = .blue, intensity: CGFloat = 0.05) {
        self.color = color
        self.intensity = intensity
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.0 - intensity : 1.0)
            .brightness(configuration.isPressed ? 0.1 : 0.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .shadow(
                color: color.opacity(configuration.isPressed ? 0.4 : 0.2),
                radius: configuration.isPressed ? 8 : 4,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
    }
}

struct ElasticButtonStyle: ButtonStyle {
    let springResponse: Double
    let dampingFraction: Double

    init(springResponse: Double = 0.4, dampingFraction: Double = 0.6) {
        self.springResponse = springResponse
        self.dampingFraction = dampingFraction
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.interactiveSpring(response: springResponse, dampingFraction: dampingFraction), value: configuration.isPressed)
    }
}

struct RippleButtonStyle: ButtonStyle {
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0
    let color: Color

    init(color: Color = .blue) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(color.opacity(rippleOpacity))
                    .scaleEffect(rippleScale)
                    .animation(.easeOut(duration: 0.6), value: rippleScale)
            )
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    withAnimation(.easeOut(duration: 0.6)) {
                        rippleScale = 2.0
                        rippleOpacity = 0.3
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        rippleScale = 0
                        rippleOpacity = 0
                    }
                }
            }
    }
}

// MARK: - Card Interaction Modifiers

struct HoverCardModifier: ViewModifier {
    @State private var isHovered = false
    let hoverScale: CGFloat
    let shadowRadius: CGFloat

    init(hoverScale: CGFloat = 1.02, shadowRadius: CGFloat = 8) {
        self.hoverScale = hoverScale
        self.shadowRadius = shadowRadius
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? hoverScale : 1.0)
            .shadow(
                color: .black.opacity(isHovered ? 0.15 : 0.05),
                radius: isHovered ? shadowRadius * 1.5 : shadowRadius,
                x: 0,
                y: isHovered ? 6 : 3
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct TapCardModifier: ViewModifier {
    @State private var isTapped = false
    let tapScale: CGFloat
    let hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle

    init(tapScale: CGFloat = 0.98, hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        self.tapScale = tapScale
        self.hapticFeedback = hapticFeedback
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isTapped ? tapScale : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isTapped)
            .onTapGesture {
                let impactFeedback = UIImpactFeedbackGenerator(style: hapticFeedback)
                impactFeedback.impactOccurred()

                withAnimation(.easeInOut(duration: 0.1)) {
                    isTapped = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isTapped = false
                    }
                }
            }
    }
}

// MARK: - Loading and Shimmer Effects

struct ShimmerModifier: ViewModifier {
    @State private var shimmerOffset: CGFloat = -1
    let duration: Double
    let opacity: Double

    init(duration: Double = 1.5, opacity: Double = 0.3) {
        self.duration = duration
        self.opacity = opacity
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(opacity),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset * UIScreen.main.bounds.width)
                    .animation(.linear(duration: duration).repeatForever(autoreverses: false), value: shimmerOffset)
            )
            .clipped()
            .onAppear {
                shimmerOffset = 1
            }
    }
}

struct SkeletonModifier: ViewModifier {
    @State private var opacity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: opacity)
            .onAppear {
                opacity = 0.7
            }
    }
}

// MARK: - Entrance Animations

struct SlideInModifier: ViewModifier {
    let edge: Edge
    let distance: CGFloat
    let delay: Double
    @State private var offset: CGFloat

    init(from edge: Edge, distance: CGFloat = 50, delay: Double = 0) {
        self.edge = edge
        self.distance = distance
        self.delay = delay

        switch edge {
        case .leading:
            self._offset = State(initialValue: -distance)
        case .trailing:
            self._offset = State(initialValue: distance)
        case .top:
            self._offset = State(initialValue: -distance)
        case .bottom:
            self._offset = State(initialValue: distance)
        }
    }

    func body(content: Content) -> some View {
        content
            .offset(
                x: (edge == .leading || edge == .trailing) ? offset : 0,
                y: (edge == .top || edge == .bottom) ? offset : 0
            )
            .opacity(offset == 0 ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    offset = 0
                }
            }
    }
}

struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0

    init(delay: Double = 0) {
        self.delay = delay
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

struct ScaleInModifier: ViewModifier {
    let delay: Double
    let initialScale: CGFloat
    @State private var scale: CGFloat

    init(delay: Double = 0, initialScale: CGFloat = 0.8) {
        self.delay = delay
        self.initialScale = initialScale
        self._scale = State(initialValue: initialScale)
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(scale == 1.0 ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    scale = 1.0
                }
            }
    }
}

// MARK: - View Extensions for Easy Use

extension View {
    func pulseButton(color: Color = .blue, intensity: CGFloat = 0.05) -> some View {
        self.buttonStyle(PulseButtonStyle(color: color, intensity: intensity))
    }

    func elasticButton(springResponse: Double = 0.4, dampingFraction: Double = 0.6) -> some View {
        self.buttonStyle(ElasticButtonStyle(springResponse: springResponse, dampingFraction: dampingFraction))
    }

    func rippleButton(color: Color = .blue) -> some View {
        self.buttonStyle(RippleButtonStyle(color: color))
    }

    func hoverCard(hoverScale: CGFloat = 1.02, shadowRadius: CGFloat = 8) -> some View {
        self.modifier(HoverCardModifier(hoverScale: hoverScale, shadowRadius: shadowRadius))
    }

    func tapCard(tapScale: CGFloat = 0.98, hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.modifier(TapCardModifier(tapScale: tapScale, hapticFeedback: hapticFeedback))
    }

    func shimmer(duration: Double = 1.5, opacity: Double = 0.3) -> some View {
        self.modifier(ShimmerModifier(duration: duration, opacity: opacity))
    }

    func skeleton() -> some View {
        self.modifier(SkeletonModifier())
    }

    func slideIn(from edge: Edge, distance: CGFloat = 50, delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(from: edge, distance: distance, delay: delay))
    }

    func fadeIn(delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(delay: delay))
    }

    func scaleIn(delay: Double = 0, initialScale: CGFloat = 0.8) -> some View {
        self.modifier(ScaleInModifier(delay: delay, initialScale: initialScale))
    }
}

// MARK: - Haptic Feedback Utilities

struct HapticFeedback {
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }

    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }

    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }

    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
}
