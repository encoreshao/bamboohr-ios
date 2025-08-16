//
//  AppRootView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct AppRootView: View {
    @State private var showLandingPage = true

    var body: some View {
        ZStack {
            if showLandingPage {
                LandingPageView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showLandingPage = false
                    }
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                MainTabView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
    }
}

#Preview {
    AppRootView()
}
