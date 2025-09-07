//
//  MainTabView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var userViewModel = UserViewModel(bambooHRService: BambooHRService.shared)
    @StateObject private var timeEntryViewModel = TimeEntryViewModel(bambooHRService: BambooHRService.shared)
    @StateObject private var leaveViewModel = LeaveViewModel(bambooHRService: BambooHRService.shared)
    @StateObject private var peopleViewModel = PeopleViewModel(bambooHRService: BambooHRService.shared)
    @StateObject private var accountSettingsViewModel = AccountSettingsViewModel(bambooHRService: BambooHRService.shared)
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var isTransitioning = false
    @State private var transitionProgress: CGFloat = 0

    var body: some View {
        FloatingTabView(selectedTab: $selectedTab) {
            ZStack {
                // Background for all views
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                // Content based on selected tab with enhanced transitions
                ZStack {
                    Group {
                        switch selectedTab {
                        case 0:
                            HomeView(viewModel: userViewModel, leaveViewModel: leaveViewModel, timeEntryViewModel: timeEntryViewModel, selectedTab: $selectedTab)
                                .modifier(CreativeTabTransition(
                                    isActive: selectedTab == 0,
                                    direction: getTransitionDirection(from: previousTab, to: 0),
                                    transitionStyle: .elastic
                                ))
                        case 1:
                            TimeEntryView(viewModel: timeEntryViewModel, selectedTab: $selectedTab)
                                .modifier(CreativeTabTransition(
                                    isActive: selectedTab == 1,
                                    direction: getTransitionDirection(from: previousTab, to: 1),
                                    transitionStyle: .bounce
                                ))
                        case 2:
                            LeaveView(viewModel: leaveViewModel, selectedTab: $selectedTab)
                                .modifier(CreativeTabTransition(
                                    isActive: selectedTab == 2,
                                    direction: getTransitionDirection(from: previousTab, to: 2),
                                    transitionStyle: .flip
                                ))
                        case 3:
                            PeopleView(viewModel: peopleViewModel, selectedTab: $selectedTab)
                                .modifier(CreativeTabTransition(
                                    isActive: selectedTab == 3,
                                    direction: getTransitionDirection(from: previousTab, to: 3),
                                    transitionStyle: .scale
                                ))
                        case 4:
                            SettingsView(viewModel: accountSettingsViewModel, selectedTab: $selectedTab)
                                .modifier(CreativeTabTransition(
                                    isActive: selectedTab == 4,
                                    direction: getTransitionDirection(from: previousTab, to: 4),
                                    transitionStyle: .slide
                                ))
                        default:
                            HomeView(viewModel: userViewModel, leaveViewModel: leaveViewModel, timeEntryViewModel: timeEntryViewModel, selectedTab: $selectedTab)
                                .modifier(CreativeTabTransition(
                                    isActive: selectedTab == 0,
                                    direction: .none,
                                    transitionStyle: .elastic
                                ))
                        }
                    }
                }
                .onChange(of: selectedTab) { oldValue, newValue in
                    previousTab = oldValue
                    withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                        isTransitioning = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isTransitioning = false
                        }
                    }
                }
            }
        }
        .withToast()
        .onAppear {
            // Check if settings are configured
            if !accountSettingsViewModel.hasValidSettings {
                selectedTab = 4 // Switch to settings tab (now at position 4)
            }
        }
    }

    // Helper function to determine transition direction
    private func getTransitionDirection(from: Int, to: Int) -> TransitionDirection {
        if from < to {
            return .forward
        } else if from > to {
            return .backward
        } else {
            return .none
        }
    }
}

// MARK: - Creative Tab Transition Modifier
struct CreativeTabTransition: ViewModifier {
    let isActive: Bool
    let direction: TransitionDirection
    let transitionStyle: TransitionStyle
    @State private var animationPhase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1.0 : 0.0)
            .scaleEffect(getScaleEffect())
            .offset(getOffsetEffect())
            .rotation3DEffect(
                getRotationEffect(),
                axis: getRotationAxis()
            )
            .blur(radius: isActive ? 0 : 2)
            .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3), value: isActive)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        animationPhase = 1.0
                    }
                }
            }
    }

    private func getScaleEffect() -> CGFloat {
        switch transitionStyle {
        case .scale:
            return isActive ? 1.0 : 0.8
        case .bounce:
            return isActive ? 1.0 + sin(animationPhase * .pi) * 0.02 : 0.9
        case .elastic:
            return isActive ? 1.0 + sin(animationPhase * .pi * 2) * 0.01 : 0.95
        default:
            return isActive ? 1.0 : 0.98
        }
    }

    private func getOffsetEffect() -> CGSize {
        let baseOffset: CGFloat = isActive ? 0 : 100

        switch (transitionStyle, direction) {
        case (.slide, .forward):
            return CGSize(width: baseOffset, height: 0)
        case (.slide, .backward):
            return CGSize(width: -baseOffset, height: 0)
        case (.bounce, _):
            return CGSize(width: 0, height: isActive ? sin(animationPhase * .pi) * 2 : baseOffset)
        default:
            return CGSize(width: 0, height: 0)
        }
    }

    private func getRotationEffect() -> Angle {
        switch transitionStyle {
        case .flip:
            return .degrees(isActive ? 0 : (direction == .forward ? 90 : -90))
        case .elastic:
            return .degrees(isActive ? sin(animationPhase * .pi) * 1 : 0)
        default:
            return .degrees(0)
        }
    }

    private func getRotationAxis() -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch transitionStyle {
        case .flip:
            return (x: 0, y: 1, z: 0)
        case .elastic:
            return (x: 0, y: 0, z: 1)
        default:
            return (x: 0, y: 0, z: 1)
        }
    }
}

// MARK: - Transition Enums
enum TransitionDirection {
    case forward, backward, none
}

enum TransitionStyle {
    case elastic, bounce, flip, scale, slide
}

#Preview {
    MainTabView()
}
