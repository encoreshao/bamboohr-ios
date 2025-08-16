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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            TimeEntry.self,
            Project.self,
            Task.self,
            AccountSettings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    // Initialize localization
                    _ = LocalizationManager.shared
                }
        }
    }
}
