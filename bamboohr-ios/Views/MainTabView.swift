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
        TabView(selection: $selectedTab) {
            HomeView(viewModel: userViewModel, leaveViewModel: leaveViewModel, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text(localizationManager.localized(.tabHome))
                }
                .tag(0)

            TimeEntryView(viewModel: timeEntryViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "clock.fill" : "clock")
                    Text(localizationManager.localized(.tabTime))
                }
                .tag(1)

            LeaveView(viewModel: leaveViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "calendar.badge.clock" : "calendar")
                    Text(localizationManager.localized(.tabLeave))
                }
                .tag(2)

            PeopleView(viewModel: peopleViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.crop.circle.fill" : "person.crop.circle")
                    Text(localizationManager.localized(.tabPeople))
                }
                .tag(3)

            SettingsView(viewModel: accountSettingsViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gear")
                    Text(localizationManager.localized(.tabSettings))
                }
                .tag(4)
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
