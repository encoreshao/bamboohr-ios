//
//  MainTabView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    // Create shared service instance
    private let bambooHRService = BambooHRService(
        accountSettings: KeychainManager.shared.loadAccountSettings()
    )

    // Create view models
    private let userViewModel: UserViewModel
    private let leaveViewModel: LeaveViewModel
    private let timeEntryViewModel: TimeEntryViewModel
    private let accountSettingsViewModel: AccountSettingsViewModel

    init() {
        // Initialize view models with the shared service
        userViewModel = UserViewModel(bambooHRService: bambooHRService)
        leaveViewModel = LeaveViewModel(bambooHRService: bambooHRService)
        timeEntryViewModel = TimeEntryViewModel(bambooHRService: bambooHRService)
        accountSettingsViewModel = AccountSettingsViewModel(bambooHRService: bambooHRService)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: userViewModel)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            LeaveView(viewModel: leaveViewModel)
                .tabItem {
                    Label("Leave", systemImage: "calendar")
                }
                .tag(1)

            TimeEntryView(viewModel: timeEntryViewModel)
                .tabItem {
                    Label("Time", systemImage: "clock")
                }
                .tag(2)

            SettingsView(viewModel: accountSettingsViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onAppear {
            // Check if settings are configured
            if KeychainManager.shared.loadAccountSettings() == nil {
                // If not configured, switch to settings tab
                selectedTab = 3
            }
        }
    }
}

#Preview {
    MainTabView()
}
