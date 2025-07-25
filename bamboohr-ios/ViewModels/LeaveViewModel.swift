//
//  LeaveViewModel.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine

class LeaveViewModel: ObservableObject {
    @Published var leaveEntries: [BambooLeaveInfo] = []
    @Published var isLoading = false
    @Published var error: String?

    private let bambooHRService: BambooHRService
    private var cancellables = Set<AnyCancellable>()

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService
    }

    func loadLeaveInfo() {
        isLoading = true
        error = nil

        // Get date range for the current month
        let today = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth)!

        bambooHRService.fetchTimeOffEntries(startDate: startOfMonth, endDate: endOfMonth)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<BambooHRError>) in
                    self?.isLoading = false

                    if case .failure(let error) = completion {
                        let localizationManager = LocalizationManager.shared
                        let errorMessage = localizationManager.localized(.networkError)

                        self?.error = errorMessage
                        ToastManager.shared.error(errorMessage)
                        print("DEBUG: Failed to load leave info: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] (entries: [BambooLeaveInfo]) in
                    self?.leaveEntries = entries
                    let localizationManager = LocalizationManager.shared
                    ToastManager.shared.success(localizationManager.localized(.leaveInfoUpdated))
                }
            )
            .store(in: &cancellables)
    }
}
