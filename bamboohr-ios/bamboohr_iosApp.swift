//
//  bamboohr_iosApp.swift
//  bamboohr-ios
//
//  Created by Encore Shao on 2025/3/15.
//

import SwiftUI
import SwiftData

@main
struct bamboohr_iosApp: App {
    @StateObject private var accountSettings: AccountSettingsViewModel
    private let bambooHRService: BambooHRService
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            TimeEntry.self,
            Project.self,
            AccountSettings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        let bambooHRService = BambooHRService()
        self.bambooHRService = bambooHRService
        _accountSettings = StateObject(wrappedValue: AccountSettingsViewModel(bambooHRService: bambooHRService))
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(bambooHRService: bambooHRService)
                .environmentObject(accountSettings)
        }
        .modelContainer(sharedModelContainer)
    }
}
