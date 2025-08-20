//
//  CelebrationViewModel.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine
import SwiftUI

class CelebrationViewModel: ObservableObject {
    @Published var celebrations: [Celebration] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let bambooHRService: BambooHRService
    private var cancellables = Set<AnyCancellable>()

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService
    }

    func loadCelebrations() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        bambooHRService.fetchCelebrations()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = self?.getErrorMessage(from: error)
                        print("ERROR: Failed to load celebrations: \(error)")
                    }
                },
                receiveValue: { [weak self] celebrations in
                    self?.celebrations = celebrations
                    print("SUCCESS: Loaded \(celebrations.count) celebrations")

                    // Check if these are sample celebrations (they have specific employee IDs)
                    let sampleIds = ["001", "002", "003", "004", "005", "006", "007", "008", "009", "010", "011", "012", "013", "014", "015", "016", "017", "018", "019", "020"]
                    let isUsingSampleData = celebrations.allSatisfy { sampleIds.contains($0.employeeId) }

                    if isUsingSampleData {
                        print("INFO: Currently displaying sample celebration data. Configure BambooHR credentials in Settings to load real employee data.")
                    } else {
                        print("INFO: Successfully loaded real employee celebration data from BambooHR API")
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func getErrorMessage(from error: BambooHRError) -> String {
        switch error {
        case .networkError:
            return "Network error occurred"
        case .authenticationError:
            return "Authentication failed"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .unknownError(let message):
            return message
        default:
            return "An unknown error occurred"
        }
    }

    // MARK: - Computed Properties

    var isUsingSampleData: Bool {
        let sampleIds = ["001", "002", "003", "004", "005", "006", "007", "008", "009", "010", "011", "012", "013", "014", "015", "016", "017", "018", "019", "020"]
        return !celebrations.isEmpty && celebrations.allSatisfy { sampleIds.contains($0.employeeId) }
    }

    var upcomingCelebrations: [Celebration] {
        let calendar = Calendar.current
        let today = Date()
        let sixMonthsFromNow = calendar.date(byAdding: .month, value: 6, to: today) ?? today

        return celebrations.filter { celebration in
            celebration.date >= today && celebration.date <= sixMonthsFromNow
        }
    }

    var todayCelebrations: [Celebration] {
        celebrations.filter { $0.isToday }
    }

    var thisWeekCelebrations: [Celebration] {
        celebrations.filter { $0.isThisWeek && !$0.isToday }
    }

    var laterCelebrations: [Celebration] {
        celebrations.filter { !$0.isThisWeek }
    }

    var groupedCelebrations: [(String, [Celebration])] {
        var groups: [(String, [Celebration])] = []

        if !todayCelebrations.isEmpty {
            groups.append(("Today", todayCelebrations))
        }

        if !thisWeekCelebrations.isEmpty {
            groups.append(("This Week", thisWeekCelebrations))
        }

        if !laterCelebrations.isEmpty {
            groups.append(("Coming Soon", laterCelebrations))
        }

        return groups
    }

    func celebrationColor(for type: CelebrationType) -> Color {
        switch type {
        case .birthday:
            return .pink
        case .workAnniversary:
            return .orange
        }
    }

    func formattedDateText(for celebration: Celebration) -> String {
        let calendar = Calendar.current

        if celebration.isToday {
            return "Today"
        } else if calendar.isDateInTomorrow(celebration.date) {
            return "Tomorrow"
        } else if celebration.isThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: celebration.date)
        } else {
            return celebration.formattedDate
        }
    }

    func timeUntilText(for celebration: Celebration) -> String {
        let days = celebration.daysUntil

        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days <= 7 {
            return "In \(days) days"
        } else {
            let weeks = days / 7
            if weeks == 1 {
                return "Next week"
            } else {
                return "In \(weeks) weeks"
            }
        }
    }
}
