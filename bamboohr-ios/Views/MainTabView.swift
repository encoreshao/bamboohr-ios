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

    var body: some View {
        FloatingTabView(selectedTab: $selectedTab) {
            ZStack {
                // Background for all views
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        HomeView(viewModel: userViewModel, leaveViewModel: leaveViewModel, timeEntryViewModel: timeEntryViewModel, selectedTab: $selectedTab)
                    case 1:
                        TimeEntryView(viewModel: timeEntryViewModel, selectedTab: $selectedTab)
                    case 2:
                        LeaveView(viewModel: leaveViewModel, selectedTab: $selectedTab)
                    case 3:
                        PeopleView(viewModel: peopleViewModel, selectedTab: $selectedTab)
                    case 4:
                        SettingsView(viewModel: accountSettingsViewModel, selectedTab: $selectedTab)
                    default:
                        HomeView(viewModel: userViewModel, leaveViewModel: leaveViewModel, timeEntryViewModel: timeEntryViewModel, selectedTab: $selectedTab)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
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
}

#Preview {
    MainTabView()
}
