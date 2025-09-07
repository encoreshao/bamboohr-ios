//
//  AppRootView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct AppRootView: View {
    @State private var showLandingPage = true
    @State private var transitionPhase: CGFloat = 0

    var body: some View {
        ZStack {
            if showLandingPage {
                LandingPageView {
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.4)) {
                        showLandingPage = false
                        transitionPhase = 1.0
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    )
                )
            } else {
                MainTabView()
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing)
                                .combined(with: .scale(scale: 0.9))
                                .combined(with: .opacity),
                            removal: .move(edge: .leading)
                                .combined(with: .scale(scale: 1.1))
                                .combined(with: .opacity)
                        )
                    )
                    .scaleEffect(1.0 + sin(transitionPhase * .pi) * 0.02)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            transitionPhase = .pi * 2
                        }
                    }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.03),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(showLandingPage ? 1.0 : 0.3)
            .animation(.easeInOut(duration: 1.0), value: showLandingPage)
        )
    }
}

#Preview {
    AppRootView()
}
