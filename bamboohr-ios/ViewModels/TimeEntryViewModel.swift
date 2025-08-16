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

                // 检查是否切换到了不同的周，如果是则重新加载本周数据
                let calendar = Calendar.current
                if !calendar.isDate(selectedDate, equalTo: oldValue, toGranularity: .weekOfYear) {
                    print("DEBUG: 📅 Week changed, reloading weekly data")
                    DispatchQueue.main.async { [weak self] in
                        self?.loadWeeklyTimeEntries(for: self?.selectedDate ?? Date())
                    }
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

    // 本周时间记录缓存
    @Published var weeklyTimeEntries: [String: [TimeEntry]] = [:] // 日期字符串 -> 时间记录数组
    private var weeklyDataCancellable: AnyCancellable?

    // 当前月时间记录缓存
    @Published var currentMonthTotalHours: Double = 0.0
    private var monthlyDataCancellable: AnyCancellable?

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
        loadWeeklyTimeEntries(for: selectedDate)
        loadCurrentMonthTotalHours()
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

    // 加载本周的时间记录数据
    func loadWeeklyTimeEntries(for selectedDate: Date) {
        weeklyDataCancellable?.cancel()

        let calendar = Calendar.current

        // 获取本周的开始日期(周一)和结束日期(周日)
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2 // 周日是1，周一是2
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate),
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            print("DEBUG: Failed to calculate week boundaries")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        print("DEBUG: 📅 Loading weekly time entries from \(dateFormatter.string(from: startOfWeek)) to \(dateFormatter.string(from: endOfWeek))")

        weeklyDataCancellable = bambooHRService.fetchTimeEntries(from: startOfWeek, to: endOfWeek)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in
                    // Handle completion if needed, silent failure for weekly data loading
                },
                receiveValue: { [weak self] entries in
                    guard let self = self else { return }

                    print("DEBUG: ✅ Received \(entries.count) weekly time entries")

                    // 清空之前的缓存
                    self.weeklyTimeEntries.removeAll()

                    // 按日期分组存储
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"

                    for entry in entries {
                        let dateKey = dateFormatter.string(from: entry.date)
                        if self.weeklyTimeEntries[dateKey] == nil {
                            self.weeklyTimeEntries[dateKey] = []
                        }
                        self.weeklyTimeEntries[dateKey]?.append(entry)
                    }

                    print("DEBUG: 📊 Cached time entries for \(self.weeklyTimeEntries.keys.count) days")
                    for (dateKey, dayEntries) in self.weeklyTimeEntries {
                        let totalHours = dayEntries.reduce(0.0) { $0 + $1.hours }
                        print("DEBUG: \(dateKey): \(dayEntries.count) entries, \(totalHours) hours")
                    }
                }
            )
    }

    // 加载当前月的总工时
    func loadCurrentMonthTotalHours() {
        monthlyDataCancellable?.cancel()

        let today = Date()
        print("DEBUG: 📊 Loading current month total hours for \(DateFormatter().string(from: today))")

        monthlyDataCancellable = fetchMonthlyTimeEntries(for: today)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("DEBUG: ❌ Failed to load monthly total hours: \(error.localizedDescription)")
                        // Don't show error toast for this background calculation
                    }
                },
                receiveValue: { [weak self] monthlyData in
                    let totalHours = monthlyData.reduce(0.0) { $0 + $1.totalHours }
                    self?.currentMonthTotalHours = totalHours
                    print("DEBUG: ✅ Current month total hours: \(totalHours)")
                }
            )
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
                    guard let self = self else { return }

                    self.isSubmitting = false
                    // Clear the form
                    self.hours = 1.0
                    self.selectedProject = nil
                    self.selectedTask = nil
                    self.note = ""

                    let localizationManager = LocalizationManager.shared
                    ToastManager.shared.success(localizationManager.localized(.timeSubmittedMessage))

                    // Reload time entries for the current date
                    self.loadTimeEntries()

                    // Reload weekly data to update the chart
                    self.loadWeeklyTimeEntries(for: self.selectedDate)

                    // Reload monthly total to update the timesheet summary
                    self.loadCurrentMonthTotalHours()
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: date)

        // 首先检查缓存的本周数据
        if let dayEntries = weeklyTimeEntries[dateKey] {
            let totalHours = dayEntries.reduce(0.0) { $0 + $1.hours }
            print("DEBUG: 💾 Using cached data for \(dateKey): \(totalHours) hours")
            return totalHours
        }

        // 如果是当前选择的日期，使用已加载的数据
        if Calendar.current.isDate(date, inSameDayAs: selectedDate) {
            return timeEntries.reduce(0.0) { $0 + $1.hours }
        }

        // 对于没有缓存数据的日期，返回0小时
        print("DEBUG: 📭 No data available for \(dateKey), returning 0 hours")
        return 0.0
    }

    // 获取本周每一天的时间记录数据
    func getWeeklyTimeData(for selectedDate: Date) -> [DayTimeData] {
        let calendar = Calendar.current
        var data: [DayTimeData] = []

        // 确保加载本周的时间记录数据
        loadWeeklyTimeEntries(for: selectedDate)

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

    // MARK: - Monthly Timesheet Methods

    func fetchMonthlyTimeEntries(for date: Date = Date()) -> AnyPublisher<[TimesheetDayData], BambooHRError> {
        let calendar = Calendar.current

        // Get the first day of the month
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return Fail(error: BambooHRError.unknownError("Failed to calculate month boundaries"))
                .eraseToAnyPublisher()
        }

        let startOfMonth = monthInterval.start
        let endOfMonth = monthInterval.end

        // Get the day before the end to get the actual last day of the month
        let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: endOfMonth) ?? endOfMonth

        return bambooHRService.fetchTimeEntries(from: startOfMonth, to: lastDayOfMonth)
            .map { [weak self] timeEntries in
                self?.processMonthlyEntries(timeEntries, for: date) ?? []
            }
            .eraseToAnyPublisher()
    }

    private func processMonthlyEntries(_ timeEntries: [TimeEntry], for date: Date) -> [TimesheetDayData] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Group entries by date
        var entriesByDate: [String: [TimeEntry]] = [:]
        for entry in timeEntries {
            let dateKey = dateFormatter.string(from: entry.date)
            if entriesByDate[dateKey] == nil {
                entriesByDate[dateKey] = []
            }
            entriesByDate[dateKey]?.append(entry)
        }

        // Get all days in the month
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }

        let startOfMonth = monthInterval.start
        let endOfMonth = monthInterval.end

        var monthlyData: [TimesheetDayData] = []
        var currentDate = startOfMonth

        while currentDate < endOfMonth {
            let dateKey = dateFormatter.string(from: currentDate)
            let dayEntries = entriesByDate[dateKey] ?? []
            let totalHours = dayEntries.reduce(0.0) { $0 + $1.hours }

            let dayData = TimesheetDayData(
                date: currentDate,
                entries: dayEntries,
                totalHours: totalHours
            )

            monthlyData.append(dayData)

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDay
        }

        return monthlyData
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

// MARK: - 月度工时表数据模型
struct TimesheetDayData {
    let date: Date
    let entries: [TimeEntry]
    let totalHours: Double

    var hasEntries: Bool {
        return !entries.isEmpty
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    var isWeekend: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
    }

    var isToday: Bool {
        return Calendar.current.isDateInToday(date)
    }
}
