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
            // 检查日期是否真的发生了变化（不是同一天）
            if !Calendar.current.isDate(selectedDate, inSameDayAs: oldValue) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                print("DEBUG: ✅ Selected date changed from \(formatter.string(from: oldValue)) to \(formatter.string(from: selectedDate))")

                // 取消之前的请求
                timeEntriesCancellable?.cancel()

                // 立即开始加载，提供更好的响应性
                DispatchQueue.main.async { [weak self] in
                    self?.loadTimeEntries()
                }
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
    private var timeEntriesCancellable: AnyCancellable?

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
        // 取消之前的加载请求
        timeEntriesCancellable?.cancel()

        // 防止重复加载
        guard !isLoadingEntries else {
            print("DEBUG: Already loading time entries, skipping duplicate request")
            return
        }

        isLoadingEntries = true
        let targetDate = selectedDate // 保存当前目标日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        print("DEBUG: 🔄 Loading time entries for date: \(dateFormatter.string(from: targetDate))")

        // 清空当前时间记录，显示加载状态，带有动画效果
        withAnimation(.easeOut(duration: 0.2)) {
            timeEntries = []
        }

        timeEntriesCancellable = bambooHRService.fetchTimeEntries(for: targetDate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<BambooHRError>) in
                    // 确保我们仍在处理正确的日期
                    guard let self = self, Calendar.current.isDate(self.selectedDate, inSameDayAs: targetDate) else {
                        print("DEBUG: ⏩ Date changed during loading, discarding results for \(dateFormatter.string(from: targetDate))")
                        return
                    }

                    self.isLoadingEntries = false

                    if case .failure(let error) = completion {
                        print("DEBUG: ❌ Failed to load time entries for \(dateFormatter.string(from: targetDate)): \(error.localizedDescription)")

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

                    // 确保我们仍在处理正确的日期
                    guard Calendar.current.isDate(self.selectedDate, inSameDayAs: targetDate) else {
                        print("DEBUG: ⏩ Date changed during loading, discarding results for \(dateFormatter.string(from: targetDate))")
                        return
                    }

                    print("DEBUG: ✅ Received \(entries.count) time entries for \(dateFormatter.string(from: targetDate))")

                    // Sort entries in reverse order to match Node.js implementation
                    // This shows the most recent entries first
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.timeEntries = entries.reversed()
                    }

                    print("DEBUG: 📋 Total hours for \(dateFormatter.string(from: targetDate)): \(self.formattedTotalHours)")

                    // Print details of loaded entries for debugging
                    for entry in entries {
                        print("DEBUG: Entry - ID: \(entry.id), Hours: \(entry.hours), Project: \(entry.projectName ?? "None"), Task: \(entry.taskName ?? "None"), Date: \(entry.date)")
                    }
                }
            )
    }

    // 强制刷新当前日期的时间记录
    func forceRefreshTimeEntries() {
        print("DEBUG: 🔄 Force refreshing time entries for current date")
        isLoadingEntries = false // 重置加载状态
        loadTimeEntries()
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
