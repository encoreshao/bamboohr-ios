//
//  LeaveViewModel.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine
import SwiftUI

class LeaveViewModel: ObservableObject {
@Published var leaveEntries: [LeaveInfo] = []
@Published var todayLeaveEntries: [LeaveInfo] = []
@Published var tomorrowLeaveEntries: [LeaveInfo] = []
@Published var isLoading = false
@Published var error: String?

    private var bambooHRService: BambooHRService
    private var cancellables = Set<AnyCancellable>()

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService
    }

    func loadLeaveInfo() {
        isLoading = true
        error = nil

        // Get today's date
        let today = Date()

        // Get date range for the current month
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth)!

        bambooHRService.fetchTimeOffEntries(startDate: startOfMonth, endDate: endOfMonth)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false

                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] entries in
                    self?.leaveEntries = entries
                    self?.updateTodayLeaveEntries()
                }
            )
            .store(in: &cancellables)
    }

    private func updateTodayLeaveEntries() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        todayLeaveEntries = leaveEntries.filter { entry in
            let startDate = calendar.startOfDay(for: entry.startDate)
            let endDate = calendar.startOfDay(for: entry.endDate)
            return (startDate...endDate).contains(today)
        }

        tomorrowLeaveEntries = leaveEntries.filter { entry in
            let startDate = calendar.startOfDay(for: entry.startDate)
            let endDate = calendar.startOfDay(for: entry.endDate)
            return (startDate...endDate).contains(tomorrow)
        }
    }
}
