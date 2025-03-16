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
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    self?.user = user
                }
            )
            .store(in: &cancellables)
    }
}
