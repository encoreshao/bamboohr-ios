//
//  MainTabView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    // Use injected service instance
    private let bambooHRService: BambooHRService

    // Create view models
    private let userViewModel: UserViewModel
    private let leaveViewModel: LeaveViewModel
    private let timeEntryViewModel: TimeEntryViewModel
    private let accountSettingsViewModel: AccountSettingsViewModel

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService
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
    let service = BambooHRService()
    MainTabView(bambooHRService: service)
}
