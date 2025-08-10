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
    @Published var timeOffCategories: [TimeOffCategory] = TimeOffCategory.defaultCategories
    @Published var isLoading = false
    @Published var error: String?
    @Published var isSubmittingRequest = false

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
                    // 移除成功消息提示，按用户建议只在首页显示成功消息
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Submit Time Off Request
    func submitTimeOffRequest(_ request: TimeOffRequest, completion: @escaping (Bool, String?) -> Void) {
        isSubmittingRequest = true

        bambooHRService.submitTimeOffRequest(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completionResult: Subscribers.Completion<BambooHRError>) in
                    self?.isSubmittingRequest = false

                    if case .failure(let error) = completionResult {
                        let errorMessage = "Failed to submit time off request: \(error.localizedDescription)"
                        ToastManager.shared.error(errorMessage)
                        completion(false, errorMessage)
                        print("DEBUG: Failed to submit time off request: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        let successMessage = "Time off request submitted successfully!"
                        ToastManager.shared.success(successMessage)
                        completion(true, successMessage)
                        // Refresh leave info after successful submission
                        self?.loadLeaveInfo()
                    } else {
                        let errorMessage = "Failed to submit time off request"
                        ToastManager.shared.error(errorMessage)
                        completion(false, errorMessage)
                    }
                }
            )
            .store(in: &cancellables)
    }


}
