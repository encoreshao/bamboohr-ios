//
//  CreativeLoadingAnimations.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

// MARK: - Creative Loading Indicators

struct PulsingDotsLoader: View {
    @State private var animationPhase: CGFloat = 0
    let color: Color
    let dotCount: Int
    let size: CGFloat

    init(color: Color = .blue, dotCount: Int = 3, size: CGFloat = 8) {
        self.color = color
        self.dotCount = dotCount
        self.size = size
    }

    var body: some View {
        HStack(spacing: size * 0.5) {
            ForEach(0..<dotCount, id: \.self) { index in
                let indexDouble = Double(index)
                let scaleValue = 1.0 + sin(animationPhase + indexDouble * 0.5) * 0.5
                let opacityValue = 0.5 + sin(animationPhase + indexDouble * 0.5) * 0.5

                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .scaleEffect(scaleValue)
                    .opacity(opacityValue)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: animationPhase)
            }
        }
        .onAppear {
            animationPhase = .pi * 2
        }
    }
}

struct WaveLoader: View {
    @State private var waveOffset: CGFloat = 0
    let color: Color
    let height: CGFloat
    let width: CGFloat

    init(color: Color = .blue, height: CGFloat = 4, width: CGFloat = 100) {
        self.color = color
        self.height = height
        self.width = width
    }

    var body: some View {
        ZStack {
            // Background track
            RoundedRectangle(cornerRadius: height / 2)
                .fill(color.opacity(0.2))
                .frame(width: width, height: height)

            // Animated wave
            RoundedRectangle(cornerRadius: height / 2)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.3),
                            color,
                            color.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width * 0.3, height: height)
                .offset(x: waveOffset)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: waveOffset)
        }
        .onAppear {
            waveOffset = width * 0.35
        }
    }
}

struct SpinningRingsLoader: View {
    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0
    @State private var rotation3: Double = 0
    let color: Color
    let size: CGFloat

    init(color: Color = .blue, size: CGFloat = 40) {
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation1))
                .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: rotation1)

            // Middle ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.7), Color.clear, color.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size * 0.7, height: size * 0.7)
                .rotationEffect(.degrees(rotation2))
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: rotation2)

            // Inner ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.clear, color, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: size * 0.4, height: size * 0.4)
                .rotationEffect(.degrees(rotation3))
                .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: rotation3)
        }
        .onAppear {
            rotation1 = 360
            rotation2 = -360
            rotation3 = 360
        }
    }
}

struct MorphingShapeLoader: View {
    @State private var morphPhase: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    let color: Color
    let size: CGFloat

    init(color: Color = .blue, size: CGFloat = 50) {
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            // Morphing shape
            RoundedRectangle(cornerRadius: size * 0.1 + morphPhase * size * 0.4)
                .fill(
                    RadialGradient(
                        colors: [
                            color,
                            color.opacity(0.7),
                            color.opacity(0.3)
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(scaleEffect)
                .rotationEffect(.degrees(rotationAngle))
                .blur(radius: morphPhase * 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                morphPhase = 1.0
                scaleEffect = 1.2
            }

            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

struct ParticleSystemLoader: View {
    @State private var particles: [LoadingParticle] = []
    @State private var animationTime: Double = 0
    let color: Color
    let particleCount: Int

    init(color: Color = .blue, particleCount: Int = 12) {
        self.color = color
        self.particleCount = particleCount
    }

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(particle.opacity),
                                color.opacity(particle.opacity * 0.5),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size * 0.5
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .scaleEffect(1.0 + sin(animationTime * 2 + particle.phase) * 0.3)
                    .blur(radius: 0.5 + sin(animationTime + particle.phase) * 0.5)
            }
        }
        .frame(width: 80, height: 80)
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { index in
            let angle = Double(index) * (2 * .pi / Double(particleCount))
            let radius: CGFloat = 30

            return LoadingParticle(
                id: UUID(),
                position: CGPoint(
                    x: 40 + CGFloat(cos(angle)) * radius,
                    y: 40 + CGFloat(sin(angle)) * radius
                ),
                size: CGFloat.random(in: 4...8),
                opacity: Double.random(in: 0.5...1.0),
                phase: Double(index) * 0.2
            )
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            animationTime += 0.05

            withAnimation(.linear(duration: 0.05)) {
                for i in particles.indices {
                    let angle = animationTime * 0.5 + particles[i].phase
                    let radius: CGFloat = 30 + sin(animationTime + particles[i].phase) * 10

                particles[i].position = CGPoint(
                    x: 40 + CGFloat(cos(angle)) * radius,
                    y: 40 + CGFloat(sin(angle)) * radius
                )

                    particles[i].opacity = 0.5 + sin(animationTime * 2 + particles[i].phase) * 0.5
                }
            }
        }
    }
}

struct LoadingParticle {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
    let phase: Double
}

// MARK: - Skeleton Loading Views

struct SkeletonCard: View {
    @State private var shimmerOffset: CGFloat = -1
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat = 200, height: CGFloat = 100, cornerRadius: CGFloat = 12) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset * (width + 50))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: shimmerOffset)
            )
            .clipped()
            .onAppear {
                shimmerOffset = 1
            }
    }
}

struct SkeletonText: View {
    @State private var shimmerOffset: CGFloat = -1
    let width: CGFloat
    let height: CGFloat

    init(width: CGFloat = 150, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset * (width + 30))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: shimmerOffset)
            )
            .clipped()
            .onAppear {
                shimmerOffset = 1
            }
    }
}

struct SkeletonCircle: View {
    @State private var shimmerOffset: CGFloat = -1
    let size: CGFloat

    init(size: CGFloat = 40) {
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset * (size + 20))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: shimmerOffset)
            )
            .clipped()
            .onAppear {
                shimmerOffset = 1
            }
    }
}

// MARK: - Loading State Manager

class LoadingStateManager: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = "Loading..."
    @Published var progress: Double = 0.0

    func startLoading(message: String = "Loading...") {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
            loadingMessage = message
            progress = 0.0
        }
    }

    func updateProgress(_ newProgress: Double, message: String? = nil) {
        withAnimation(.easeInOut(duration: 0.2)) {
            progress = min(max(newProgress, 0.0), 1.0)
            if let message = message {
                loadingMessage = message
            }
        }
    }

    func stopLoading() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
            progress = 0.0
        }
    }
}

// MARK: - View Extensions

extension View {
    func pulsingDotsLoader(color: Color = .blue, dotCount: Int = 3, size: CGFloat = 8) -> some View {
        PulsingDotsLoader(color: color, dotCount: dotCount, size: size)
    }

    func waveLoader(color: Color = .blue, height: CGFloat = 4, width: CGFloat = 100) -> some View {
        WaveLoader(color: color, height: height, width: width)
    }

    func spinningRingsLoader(color: Color = .blue, size: CGFloat = 40) -> some View {
        SpinningRingsLoader(color: color, size: size)
    }

    func morphingShapeLoader(color: Color = .blue, size: CGFloat = 50) -> some View {
        MorphingShapeLoader(color: color, size: size)
    }

    func particleSystemLoader(color: Color = .blue, particleCount: Int = 12) -> some View {
        ParticleSystemLoader(color: color, particleCount: particleCount)
    }
}
