//
//  AccountSettingsViewModel.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine
import SwiftUI

class AccountSettingsViewModel: ObservableObject {
    @Published var companyDomain: String = ""
    @Published var employeeId: String = ""
    @Published var apiKey: String = ""
    @Published var isLoading = false
    @Published var isTesting = false
    @Published var error: String?
    @Published var successMessage: String?

    private var bambooHRService: BambooHRService
    private var cancellables = Set<AnyCancellable>()

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService
        loadSettings()
    }

    var hasValidSettings: Bool {
        return !companyDomain.isEmpty && !employeeId.isEmpty && !apiKey.isEmpty
    }

    var hasRequiredFields: Bool {
        return !companyDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !employeeId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadSettings() {
        if let settings = KeychainManager.shared.loadAccountSettings() {
            companyDomain = settings.companyDomain
            employeeId = settings.employeeId
            apiKey = settings.apiKey

            // Update the service with the loaded settings
            bambooHRService.updateAccountSettings(settings)
        }
    }

    func saveSettings() {
        guard !companyDomain.isEmpty, !employeeId.isEmpty, !apiKey.isEmpty else {
            let localizationManager = LocalizationManager.shared
            ToastManager.shared.error(localizationManager.localized(.allFieldsRequired))
            return
        }

        isTesting = true

        let settings = AccountSettings(
            companyDomain: companyDomain.trimmingCharacters(in: .whitespacesAndNewlines),
            employeeId: employeeId.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        // Save to keychain first
        do {
            try KeychainManager.shared.saveAccountSettings(settings)
            // Test the connection
            testConnection()
        } catch {
            isTesting = false
            let localizationManager = LocalizationManager.shared
            ToastManager.shared.error(localizationManager.localized(.connectionTestFailed))
        }
    }

    func clearSettings() {
        do {
            try KeychainManager.shared.clearAccountSettings()
            companyDomain = ""
            employeeId = ""
            apiKey = ""

            let localizationManager = LocalizationManager.shared
            ToastManager.shared.success(localizationManager.localized(.settingsCleared))
        } catch {
            let localizationManager = LocalizationManager.shared
            ToastManager.shared.error(localizationManager.localized(.connectionTestFailed))
        }
    }

    func testConnection() {
        guard hasValidSettings else {
            let localizationManager = LocalizationManager.shared
            ToastManager.shared.error(localizationManager.localized(.allFieldsRequired))
            return
        }

        isTesting = true

        // Test by fetching user info
        BambooHRService.shared.fetchCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<BambooHRError>) in
                    self?.isTesting = false

                    if case .failure(let error) = completion {
                        print("DEBUG: Connection test failed: \(error.localizedDescription)")
                        let localizationManager = LocalizationManager.shared
                        ToastManager.shared.error(localizationManager.localized(.connectionTestFailed))
                    }
                },
                receiveValue: { [weak self] (_: User) in
                    self?.isTesting = false
                    let localizationManager = LocalizationManager.shared
                    ToastManager.shared.success(localizationManager.localized(.settingsSaved))
                }
            )
            .store(in: &cancellables)
    }
}
