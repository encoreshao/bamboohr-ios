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
    @Published var isSaving = false
    @Published var error: String?
    @Published var successMessage: String?
    @Published var isConfigured = false

    private var bambooHRService: BambooHRService
    private var cancellables = Set<AnyCancellable>()

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService
        loadSettings()
    }

    func loadSettings() {
        if let settings = KeychainManager.shared.loadAccountSettings() {
            companyDomain = settings.companyDomain
            employeeId = settings.employeeId
            apiKey = settings.apiKey
            isConfigured = true

            // Update the service with the loaded settings
            bambooHRService.updateAccountSettings(settings)
        } else {
            isConfigured = false
        }
    }

    func saveSettings() {
        guard !companyDomain.isEmpty, !employeeId.isEmpty, !apiKey.isEmpty else {
            error = "All fields are required"
            return
        }

        isSaving = true
        error = nil
        successMessage = nil

        let settings = AccountSettings(
            companyDomain: companyDomain,
            employeeId: employeeId,
            apiKey: apiKey,
            lastSyncDate: Date()
        )

        do {
            try KeychainManager.shared.saveAccountSettings(settings)

            // Update the service with the new settings
            bambooHRService.updateAccountSettings(settings)

            // Test the connection
            testConnection()
        } catch {
            self.isSaving = false
            self.error = "Failed to save settings: \(error.localizedDescription)"
        }
    }

    func clearSettings() {
        do {
            try KeychainManager.shared.clearAccountSettings()
            companyDomain = ""
            employeeId = ""
            apiKey = ""
            isConfigured = false
            successMessage = "Settings cleared successfully"
        } catch {
            self.error = "Failed to clear settings: \(error.localizedDescription)"
        }
    }

    private func testConnection() {
        bambooHRService.fetchCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSaving = false

                    if case .failure(let error) = completion {
                        self?.error = "Connection test failed: \(error.localizedDescription)"
                        self?.isConfigured = false
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.successMessage = "Settings saved and connection verified"
                    self?.isConfigured = true
                }
            )
            .store(in: &cancellables)
    }
}
