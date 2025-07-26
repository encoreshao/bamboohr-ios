//
//  TimeEntryViewModel.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine
import SwiftUI

class TimeEntryViewModel: ObservableObject {
    @Published var timeEntries: [TimeEntry] = []
    @Published var projects: [Project] = []
    @Published var selectedDate = Date() {
        didSet {
            if selectedDate != oldValue {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                print("DEBUG: ✅ Selected date changed from \(formatter.string(from: oldValue)) to \(formatter.string(from: selectedDate))")

                // 立即加载新日期的时间记录
                loadTimeEntries()
            }
        }
    }
    @Published var hours: Double = 8.0
    @Published var selectedProject: Project?
    @Published var selectedTask: Task?
    @Published var note: String = ""
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var isLoadingEntries = false
    @Published var error: String?
    @Published var successMessage: String?

    private var bambooHRService: BambooHRService
    private var cancellables = Set<AnyCancellable>()

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService

        // Reset selected task when selected project changes
        $selectedProject
            .sink { [weak self] project in
                self?.selectedTask = nil
            }
            .store(in: &cancellables)

        // Load initial data
        loadProjects()
        loadTimeEntries()
    }

    func loadProjects() {
        isLoading = true

        bambooHRService.fetchProjects()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<BambooHRError>) in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        let localizationManager = LocalizationManager.shared
                        let errorMessage = localizationManager.localized(.projectsLoadFailed)
                        self?.error = errorMessage
                        ToastManager.shared.error(errorMessage)
                        print("DEBUG: Failed to load projects: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] (projects: [Project]) in
                    self?.projects = projects
                    // 移除成功消息提示，按用户建议只在首页显示成功消息
                }
            )
            .store(in: &cancellables)
    }

    func loadTimeEntries() {
        // 防止重复加载
        guard !isLoadingEntries else {
            print("DEBUG: Already loading time entries, skipping duplicate request")
            return
        }

        isLoadingEntries = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        print("DEBUG: 🔄 Loading time entries for date: \(dateFormatter.string(from: selectedDate))")

        bambooHRService.fetchTimeEntries(for: selectedDate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<BambooHRError>) in
                    self?.isLoadingEntries = false
                    if case .failure(let error) = completion {
                        print("DEBUG: ❌ Failed to load time entries for \(self?.selectedDate ?? Date()): \(error.localizedDescription)")

                        // Only show error toast for authentication or network errors
                        // Don't show error for 404 (time tracking might not be enabled)
                        switch error {
                        case .authenticationError:
                            let localizationManager = LocalizationManager.shared
                            let errorMessage = localizationManager.localized(.authenticationError)
                            ToastManager.shared.error(errorMessage)
                        case .networkError(_):
                            let localizationManager = LocalizationManager.shared
                            let errorMessage = localizationManager.localized(.networkError)
                            ToastManager.shared.error(errorMessage)
                        default:
                            // For other errors (like 404), just log them without showing toast
                            print("DEBUG: Time tracking might not be enabled for this account")
                        }
                    }
                },
                receiveValue: { [weak self] (entries: [TimeEntry]) in
                    guard let self = self else { return }

                    // 确保这是当前选择日期的数据
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    print("DEBUG: ✅ Received \(entries.count) time entries for \(dateFormatter.string(from: self.selectedDate))")

                    // Sort entries in reverse order to match Node.js implementation
                    // This shows the most recent entries first
                    self.timeEntries = entries.reversed()

                    print("DEBUG: 📋 Total hours for \(dateFormatter.string(from: self.selectedDate)): \(self.formattedTotalHours)")

                    // Print details of loaded entries for debugging
                    for entry in entries {
                        print("DEBUG: Entry - ID: \(entry.id), Hours: \(entry.hours), Project: \(entry.projectName ?? "None"), Task: \(entry.taskName ?? "None"), Date: \(entry.date)")
                    }

                    // 移除成功消息提示，按用户建议只在首页显示成功消息
                }
            )
            .store(in: &cancellables)
    }

    func submitTimeEntry() {
        guard let project = selectedProject else {
            let localizationManager = LocalizationManager.shared
            ToastManager.shared.error(localizationManager.localized(.timeSelectProject))
            return
        }

        isSubmitting = true

        let entry = TimeEntry(
            id: UUID().uuidString,
            employeeId: KeychainManager.shared.loadAccountSettings()?.employeeId ?? "",
            date: selectedDate,
            hours: hours,
            projectId: project.id,
            projectName: project.name,
            taskId: selectedTask?.id,
            taskName: selectedTask?.name,
            note: note
        )

        bambooHRService.submitTimeEntry(entry)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<BambooHRError>) in
                    self?.isSubmitting = false
                    if case .failure(let error) = completion {
                        print("DEBUG: Failed to submit time entry: \(error.localizedDescription)")
                        let localizationManager = LocalizationManager.shared
                        ToastManager.shared.error(localizationManager.localized(.projectsLoadFailed))
                    }
                },
                receiveValue: { [weak self] (_: Bool) in
                    self?.isSubmitting = false
                    // Clear the form
                    self?.hours = 1.0
                    self?.selectedProject = nil
                    self?.selectedTask = nil
                    self?.note = ""

                    let localizationManager = LocalizationManager.shared
                    ToastManager.shared.success(localizationManager.localized(.timeSubmittedMessage))

                    // Reload time entries for the current date
                    self?.loadTimeEntries()
                }
            )
            .store(in: &cancellables)
    }

    private func resetForm() {
        hours = 8.0
        note = ""
        selectedDate = Date()
        selectedTask = nil
    }

    var totalHoursForDate: Double {
        timeEntries.reduce(0) { $0 + $1.hours }
    }

    // MARK: - Computed Properties
    var formattedTotalHours: String {
        let total = timeEntries.reduce(0.0) { $0 + $1.hours }
        return String(format: "%.1f", total)
    }

    // MARK: - Data Loading Methods
}
