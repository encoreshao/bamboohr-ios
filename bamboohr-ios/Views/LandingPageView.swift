//
//  LandingPageView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct LandingPageView: View {
    @State private var isAnimating = false
    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @State private var logoRotation: Double = 0.0
    @State private var brandTextOffset: CGFloat = -50
    @State private var poweredByOffset: CGFloat = 50
    @State private var loadingDotsOffset: CGFloat = 30
    @State private var glowIntensity: Double = 0.0
    @State private var particleOpacity: Double = 0.0
    @State private var currentCharacterIndex: Int = 0
    @State private var showCharacterAnimation: Bool = false
    @State private var characterOpacity: Double = 0.0

    private let ekoheCharacters = ["E", "k", "o", "h", "E"]

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(backgroundOpacity)
            .ignoresSafeArea()

            // Enhanced floating particles animation
            ParticlesView()
                .opacity(particleOpacity)

            VStack(spacing: 32) {
                Spacer()

                // Logo and App Icon
                VStack(spacing: 24) {
                                        // App Icon with enhanced animations
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(glowIntensity), Color.purple.opacity(glowIntensity)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(logoRotation))
                            .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: logoRotation)

                        // Main logo circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .scaleEffect(logoScale)
                            .shadow(color: .blue.opacity(0.4), radius: 25, x: 0, y: 15)
                            .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 8)

                        // Animated Ekohe characters
                        if showCharacterAnimation && currentCharacterIndex < ekoheCharacters.count {
                            Text(ekoheCharacters[currentCharacterIndex])
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .scaleEffect(logoScale)
                                .opacity(characterOpacity)
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                                .animation(.easeInOut(duration: 0.3), value: characterOpacity)
                        } else {
                            // Default building icon before character animation starts
                            Image(systemName: "building.2.crop.circle.fill")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(.white)
                                .scaleEffect(logoScale)
                                .rotationEffect(.degrees(-logoRotation * 0.3))
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                                .opacity(showCharacterAnimation ? 0 : 1)
                                .animation(.easeInOut(duration: 0.3), value: showCharacterAnimation)
                        }

                        // Pulse effect
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 140, height: 140)
                            .scaleEffect(logoScale * (1.0 + sin(logoRotation * .pi / 180) * 0.05))
                    }

                                        // Main brand text with enhanced animations
                    VStack(spacing: 12) {
                        Text("BambooHR")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(textOpacity)
                            .offset(y: brandTextOffset)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

                        // Powered by text with staggered animation
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 1)
                                .scaleEffect(x: textOpacity, y: 1.0)

                            Text("Powered by")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)

                            Text("Ekohe")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)

                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 1)
                                .scaleEffect(x: textOpacity, y: 1.0)
                        }
                        .opacity(textOpacity)
                        .offset(y: poweredByOffset)
                    }
                }

                Spacer()

                                // Enhanced loading indicator
                VStack(spacing: 16) {
                    // Enhanced loading animation with wave effect
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 6, height: 6)
                                .scaleEffect(isAnimating ? 1.2 : 0.3)
                                .opacity(isAnimating ? 1.0 : 0.3)
                                .animation(
                                    .easeInOut(duration: 1.0)
                                    .repeatForever()
                                    .delay(Double(index) * 0.15),
                                    value: isAnimating
                                )
                                .shadow(color: .blue.opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                    }
                    .opacity(textOpacity)
                    .offset(y: loadingDotsOffset)

                    Text("Loading your workspace...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .opacity(textOpacity * 0.8)
                        .offset(y: loadingDotsOffset)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimations()

            // Auto-dismiss after 3.5 seconds to allow full character animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    onComplete()
                }
            }
        }
    }

    private func startAnimations() {
        // Background fade in
        withAnimation(.easeOut(duration: 0.4)) {
            backgroundOpacity = 1.0
        }

        // Particles fade in
        withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
            particleOpacity = 0.6
        }

        // Logo scale and glow
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            logoScale = 1.0
        }

        withAnimation(.easeInOut(duration: 0.5).delay(0.4)) {
            glowIntensity = 0.8
        }

        // Logo rotation (continuous)
        withAnimation(.linear(duration: 0.1).delay(0.5)) {
            logoRotation = 360.0
        }

                // Start Ekohe character animation after logo is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            startCharacterAnimation()
        }

        // Brand text slide in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.5)) {
            brandTextOffset = 0
            textOpacity = 1.0
        }

        // Powered by text slide in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.7)) {
            poweredByOffset = 0
        }

        // Loading dots slide in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.9)) {
            loadingDotsOffset = 0
        }

        // Start loading animation
        withAnimation(.easeInOut(duration: 0.4).delay(2.1)) {
            isAnimating = true
        }
    }

    private func startCharacterAnimation() {
        showCharacterAnimation = true

        // Function to animate each character
        func animateCharacter(at index: Int) {
            guard index < ekoheCharacters.count else { return }

            currentCharacterIndex = index

                        // Fade in current character faster
            withAnimation(.easeInOut(duration: 0.2)) {
                characterOpacity = 1.0
            }

            // Hold the character for shorter time, then fade out and move to next
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    characterOpacity = 0.0
                }

                // Move to next character after fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    animateCharacter(at: index + 1)
                }
            }
        }

        // Start the character animation sequence
        animateCharacter(at: 0)
    }
}

// MARK: - Particles Animation View
struct ParticlesView: View {
    @State private var particles: [Particle] = []

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .animation(
                        .linear(duration: particle.duration).repeatForever(autoreverses: false),
                        value: particle.position
                    )
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }

    private func createParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        particles = (0..<15).map { _ in
            Particle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                ),
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.1...0.4),
                duration: Double.random(in: 3...8)
            )
        }
    }

    private func animateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in 0..<particles.count {
                let randomX = CGFloat.random(in: -20...screenWidth + 20)
                let randomY = CGFloat.random(in: -20...screenHeight + 20)
                particles[i].position = CGPoint(x: randomX, y: randomY)
            }
        }
    }
}

// MARK: - Particle Model
struct Particle {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    let opacity: Double
    let duration: Double
}

#Preview {
    LandingPageView {
        print("Landing page completed")
    }
}
