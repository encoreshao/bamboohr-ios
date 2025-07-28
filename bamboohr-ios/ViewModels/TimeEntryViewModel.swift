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

    // 获取指定日期的时间记录总数
    func getTotalHours(for date: Date) -> Double {
        // 如果是当前选择的日期，直接使用已加载的数据
        if Calendar.current.isDate(date, inSameDayAs: selectedDate) {
            return timeEntries.reduce(0.0) { $0 + $1.hours }
        }

        // 对于其他日期，这里应该从API获取，暂时返回模拟数据
        // TODO: 实现从API获取指定日期的时间记录
        return generateMockHours(for: date)
    }

    // 获取本周每一天的时间记录数据
    func getWeeklyTimeData(for selectedDate: Date) -> [DayTimeData] {
        let calendar = Calendar.current
        var data: [DayTimeData] = []

        // 获取本周的开始日期(周一)
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2 // 周日是1，周一是2
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate) else { return data }

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }

            let hours = getTotalHours(for: date)
            let isToday = calendar.isDate(date, inSameDayAs: Date())

            let dayData = DayTimeData(
                date: date,
                hours: hours,
                dayLabel: formatDayLabel(date),
                isToday: isToday,
                height: 0 // 会在视图中重新计算
            )

            data.append(dayData)
        }

        return data
    }

    // 格式化日期标签
    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // 周几的简写
        let localizationManager = LocalizationManager.shared
        if localizationManager.currentLanguage == "zh-Hans" {
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: date)
    }

    // 生成模拟数据（临时使用，直到实现真实数据获取）
    private func generateMockHours(for date: Date) -> Double {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        // 周末较少工作时间
        if weekday == 1 || weekday == 7 { // 周日或周六
            return Double.random(in: 0...2)
        } else {
            // 工作日
            return Double.random(in: 6...9)
        }
    }

    // MARK: - Data Loading Methods
}

// MARK: - 周数据模型
struct DayTimeData {
    let date: Date
    let hours: Double
    let dayLabel: String
    let isToday: Bool
    var height: CGFloat // 改为var以便修改
}
