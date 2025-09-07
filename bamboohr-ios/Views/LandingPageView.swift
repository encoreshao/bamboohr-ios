//
//  LandingPageView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI
import WebKit

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

    // Enhanced animation states
    @State private var morphingScale: CGFloat = 1.0
    @State private var rippleEffect: CGFloat = 0.0
    @State private var breathingEffect: CGFloat = 1.0
    @State private var colorShift: Double = 0.0
    @State private var waveOffset: CGFloat = 0.0
    @State private var sparkleOpacity: Double = 0.0
    @State private var logoBlur: CGFloat = 0.0
    @State private var energyPulse: CGFloat = 1.0

    private let ekoheCharacters = ["E", "K", "O", "H", "E"]

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
                        // Enhanced ripple effects
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(glowIntensity * (0.8 - Double(index) * 0.2)),
                                            Color.purple.opacity(glowIntensity * (0.6 - Double(index) * 0.15)),
                                            Color.cyan.opacity(glowIntensity * (0.4 - Double(index) * 0.1))
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3 - CGFloat(index)
                                )
                                .frame(width: 140 + CGFloat(index) * 20 + rippleEffect,
                                       height: 140 + CGFloat(index) * 20 + rippleEffect)
                                .opacity(1.0 - Double(index) * 0.3)
                                .rotationEffect(.degrees(logoRotation + Double(index) * 30))
                                .scaleEffect(breathingEffect)
                        }

                        // Sparkle effects around logo
                        ForEach(0..<8, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(sparkleOpacity))
                                .frame(width: 4, height: 4)
                                .offset(
                                    x: cos(Double(index) * .pi / 4 + colorShift) * 80,
                                    y: sin(Double(index) * .pi / 4 + colorShift) * 80
                                )
                                .blur(radius: 1)
                                .scaleEffect(1.0 + sin(colorShift + Double(index)) * 0.5)
                        }

                        // Main logo circle with morphing effects
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.blue.opacity(0.9 + sin(colorShift) * 0.1),
                                        Color.purple.opacity(0.8 + cos(colorShift * 1.2) * 0.2),
                                        Color.cyan.opacity(0.6 + sin(colorShift * 0.8) * 0.3)
                                    ],
                                    center: UnitPoint(x: 0.5 + sin(colorShift) * 0.1, y: 0.5 + cos(colorShift) * 0.1),
                                    startRadius: 10,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 140 * morphingScale, height: 140 * morphingScale)
                            .scaleEffect(logoScale * energyPulse)
                            .blur(radius: logoBlur)
                            .shadow(color: .blue.opacity(0.6), radius: 30, x: 0, y: 20)
                            .shadow(color: .purple.opacity(0.4), radius: 20, x: 0, y: 10)
                            .shadow(color: .cyan.opacity(0.3), radius: 40, x: 0, y: 25)

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
        // Background fade in with wave effect
        withAnimation(.easeOut(duration: 0.4)) {
            backgroundOpacity = 1.0
        }

        // Particles fade in
        withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
            particleOpacity = 0.6
        }

        // Enhanced logo animations with morphing effects
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            logoScale = 1.0
        }

        withAnimation(.easeInOut(duration: 0.5).delay(0.4)) {
            glowIntensity = 0.8
        }

        // Continuous morphing and breathing effects
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
            morphingScale = 1.1
            breathingEffect = 1.05
        }

        // Ripple effect animation
        withAnimation(.easeOut(duration: 1.5).repeatForever().delay(0.6)) {
            rippleEffect = 50.0
        }

        // Color shifting animation
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false).delay(0.7)) {
            colorShift = .pi * 2
        }

        // Sparkle animation
        withAnimation(.easeInOut(duration: 0.8).delay(0.8)) {
            sparkleOpacity = 0.8
        }

        // Energy pulse effect
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.9)) {
            energyPulse = 1.08
        }

        // Logo rotation (continuous)
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false).delay(0.5)) {
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
    @State private var animationTime: Double = 0

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                ZStack {
                    // Main particle with enhanced gradient
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(particle.opacity * 0.8),
                                    Color.purple.opacity(particle.opacity * 0.6),
                                    Color.cyan.opacity(particle.opacity * 0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: particle.size * 0.8
                            )
                        )
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .scaleEffect(1.0 + sin(animationTime * 2 + particle.duration) * 0.3)
                        .blur(radius: 1 + sin(animationTime + particle.duration) * 0.5)

                    // Particle glow effect
                    Circle()
                        .fill(Color.white.opacity(particle.opacity * 0.3))
                        .frame(width: particle.size * 0.5, height: particle.size * 0.5)
                        .position(particle.position)
                        .blur(radius: 3)
                        .scaleEffect(1.0 + cos(animationTime * 3 + particle.duration) * 0.4)
                }
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

        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            animationTime += 0.05

            withAnimation(.linear(duration: 0.05)) {
                for i in 0..<particles.count {
                    // Enhanced floating movement with sine waves
                    let baseSpeed = particles[i].duration * 0.1
                    let waveX = sin(animationTime * 0.5 + particles[i].duration) * 30
                    let waveY = cos(animationTime * 0.3 + particles[i].duration) * 20

                    particles[i].position.x += CGFloat(waveX * baseSpeed)
                    particles[i].position.y += CGFloat(waveY * baseSpeed - 0.5)

                    // Wrap around screen edges with smooth transitions
                    if particles[i].position.x > screenWidth + 50 {
                        particles[i].position.x = -50
                    } else if particles[i].position.x < -50 {
                        particles[i].position.x = screenWidth + 50
                    }

                    if particles[i].position.y > screenHeight + 50 {
                        particles[i].position.y = -50
                    } else if particles[i].position.y < -50 {
                        particles[i].position.y = screenHeight + 50
                    }
                }
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

// MARK: - Ekohe SVG View
struct EkoheSVGView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false

        // Load the SVG from URL
        let svgURL = URL(string: "https://cdn.ekohe.com/cms-assets/Ekohe_Gradient_Icon_1_4d1f041f5c.svg")!
        let request = URLRequest(url: svgURL)
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
}

#Preview {
    LandingPageView {
        print("Landing page completed")
    }
}
