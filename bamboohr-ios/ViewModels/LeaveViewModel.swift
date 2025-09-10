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
    @Published var myTimeOffRequests: [BambooLeaveInfo] = []
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

        // Load approved leave entries (for everyone) - this keeps LeaveView working
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
                    print("DEBUG: Loaded \(entries.count) general leave entries for LeaveView")
                }
            )
            .store(in: &cancellables)

        // Separately load personal time off requests for HomeView
        loadMyTimeOffRequests()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("DEBUG: Failed to load personal time off requests: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] (myRequests: [BambooLeaveInfo]) in
                    self?.myTimeOffRequests = myRequests
                    print("DEBUG: Loaded \(myRequests.count) personal requests for HomeView")

                    // Debug log personal requests details
                    for request in myRequests {
                        print("DEBUG: Personal request - id: \(request.id), type: \(request.type), start: \(request.start), end: \(request.end), status: \(request.status ?? "none")")
                    }
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Load My Time Off Requests
    func loadMyTimeOffRequests() -> AnyPublisher<[BambooLeaveInfo], BambooHRError> {
        // Get date range from 3 months ago to 6 months in future
        let today = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: 0, to: today)!
        let endDate = calendar.date(byAdding: .month, value: 6, to: today)!

        return bambooHRService.fetchTimeOffRequests(startDate: startDate, endDate: endDate)
    }

    // MARK: - Submit Time Off Request
    func submitTimeOffRequest(_ request: TimeOffRequest, completion: @escaping (Bool, String?) -> Void) {
        isSubmittingRequest = true

        // Get employee ID from account settings
        guard let employeeId = KeychainManager.shared.loadAccountSettings()?.employeeId else {
            let errorMessage = "Unable to get employee ID for time off request"
            ToastManager.shared.error(errorMessage)
            completion(false, errorMessage)
            isSubmittingRequest = false
            return
        }

        bambooHRService.submitTimeOffRequest(request, employeeId: employeeId)
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
