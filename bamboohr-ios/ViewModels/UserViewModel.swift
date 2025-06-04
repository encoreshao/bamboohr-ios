//
//  UserViewModel.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine
import SwiftUI

class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?

    private var bambooHRService: BambooHRService
    private var cancellables = Set<AnyCancellable>()

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService
    }

    func loadUserInfo() {
        isLoading = true
        error = nil
        bambooHRService.fetchCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("DEBUG: HomeView loadUserInfo error: \(error)")
                        self?.error = "Could not load your profile. Please check your network or BambooHR settings."
                    }
                },
                receiveValue: { [weak self] user in
                    self?.user = user
                }
            )
            .store(in: &cancellables)
    }

    // Helper to calculate next birthday
    static func calculateNextBirthday(birthdayString: String?) -> Date? {
        guard let birthdayString = birthdayString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        let year = Calendar.current.component(.year, from: Date())
        guard let birthday = formatter.date(from: birthdayString) else { return nil }
        var components = Calendar.current.dateComponents([.month, .day], from: birthday)
        components.year = year
        let thisYearBirthday = Calendar.current.date(from: components) ?? Date()
        if thisYearBirthday < Date() {
            components.year = year + 1
        }
        return Calendar.current.date(from: components)
    }
}
