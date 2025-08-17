//
//  TimesheetView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI
import Combine

struct TimesheetView: View {
    @ObservedObject var viewModel: TimeEntryViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedDate = Date()
    @State private var timesheetData: [TimesheetDayData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 0) {
            // Month selector
            monthSelectorView

            if isLoading {
                loadingView
            } else if timesheetData.isEmpty {
                emptyStateView
            } else {
                // Calendar grid and timesheet list
                ScrollView {
                    VStack(spacing: 16) {
                        monthlyCalendarView
                        timesheetListView
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle(getLocalizedText("我的工时表", "My Timesheet"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(getLocalizedText("今天", "Today")) {
                    selectedDate = Date()
                    loadTimesheetData()
                }
                .navigationGradientButtonStyle(color: .purple)
            }
        }
        .onAppear {
            loadTimesheetData()
        }
        .onChange(of: selectedDate) { _, _ in
            loadTimesheetData()
        }
    }

    // MARK: - Month Selector
    private var monthSelectorView: some View {
        HStack {
            Button(action: {
                if let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
                    selectedDate = previousMonth
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.purple)
                    .font(.title2)
            }

            Spacer()

            Text(monthYearFormatter.string(from: selectedDate))
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            if !isCurrentMonth {
                Button(action: {
                    if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
                        selectedDate = nextMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.purple)
                        .font(.title2)
                }
            } else {
                // Placeholder to maintain layout balance
                Image(systemName: "chevron.right")
                    .foregroundColor(.clear)
                    .font(.title2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(getLocalizedText("正在加载工时表...", "Loading timesheet..."))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(getLocalizedText("本月暂无工时记录", "No time entries this month"))
                .font(.headline)
                .foregroundColor(.secondary)

            Text(getLocalizedText("开始记录您的工作时间吧！", "Start tracking your work hours!"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Monthly Calendar View
    private var monthlyCalendarView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title3)

                Text(getLocalizedText("本月概览", "Month Overview"))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(getLocalizedText("总工时", "Total Hours"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", totalMonthHours)) \(getLocalizedText("小时", "hours"))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }

                        // Calendar grid (smaller size)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                // Weekday headers
                ForEach(weekdayHeaders, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(height: 20)
                }

                // Calendar days
                ForEach(calendarDays, id: \.date) { dayData in
                    CalendarDayView(dayData: dayData)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - Timesheet List View
    private var timesheetListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.clipboard.fill")
                    .foregroundColor(.purple)
                    .font(.title3)

                Text(getLocalizedText("工时详情", "Time Details"))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            LazyVStack(spacing: 6) {
                ForEach(workingDays, id: \.date) { dayData in
                    TimesheetDayRowView(dayData: dayData)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - Computed Properties

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        if localizationManager.currentLanguage == "zh-Hans" {
            formatter.dateFormat = "yyyy年 M月"
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter
    }

    private var weekdayHeaders: [String] {
        let formatter = DateFormatter()
        if localizationManager.currentLanguage == "zh-Hans" {
            formatter.locale = Locale(identifier: "zh_CN")
            return ["日", "一", "二", "三", "四", "五", "六"]
        } else {
            formatter.locale = Locale(identifier: "en_US")
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        }
    }

    private var calendarDays: [TimesheetDayData] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else {
            return timesheetData
        }

        let startOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)

        // Add empty days for the beginning of the month
        var allDays: [TimesheetDayData] = []

        // Add empty days from previous month to fill the first week
        for i in 1..<firstWeekday {
            if let previousDay = calendar.date(byAdding: .day, value: -(firstWeekday - i), to: startOfMonth) {
                allDays.append(TimesheetDayData(date: previousDay, entries: [], totalHours: 0))
            }
        }

        // Add actual month days
        allDays.append(contentsOf: timesheetData)

        return allDays
    }

    private var workingDays: [TimesheetDayData] {
        return timesheetData.filter { $0.hasEntries }.sorted { $0.date > $1.date }
    }

    private var totalMonthHours: Double {
        return timesheetData.reduce(0) { $0 + $1.totalHours }
    }

    private var isCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Helper Methods

    private func loadTimesheetData() {
        isLoading = true
        errorMessage = nil

        viewModel.fetchMonthlyTimeEntries(for: selectedDate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        print("DEBUG: Failed to load monthly timesheet: \(error.localizedDescription)")
                    }
                },
                receiveValue: { data in
                    timesheetData = data
                    print("DEBUG: Loaded \(data.count) days of timesheet data")
                }
            )
            .store(in: &cancellables)
    }

    private func getLocalizedText(_ chinese: String, _ english: String) -> String {
        return localizationManager.currentLanguage == "zh-Hans" ? chinese : english
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let dayData: TimesheetDayData

    var body: some View {
        VStack(spacing: 1) {
            Text(dayData.formattedDate)
                .font(.caption2)
                .fontWeight(dayData.isToday ? .bold : .regular)
                .foregroundColor(dayData.isToday ? .white : (dayData.isWeekend ? .secondary : .primary))

            if dayData.hasEntries {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: 24, height: 28)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    dayData.isToday ? Color.purple :
                    (dayData.isWeekend ? Color(.systemGray5) : Color.clear)
                )
        )
    }
}

// MARK: - Timesheet Day Row View
struct TimesheetDayRowView: View {
    let dayData: TimesheetDayData
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedDate)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(dayData.dayOfWeek)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(String(format: "%.1f", dayData.totalHours)) \(getLocalizedText("小时", "hours"))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)

                        Text("\(dayData.entries.count) \(getLocalizedText("条记录", "entries"))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded entries list
            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(dayData.entries, id: \.id) { entry in
                        TimeEntryRowView(entry: entry)
                    }
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        if localizationManager.currentLanguage == "zh-Hans" {
            formatter.dateFormat = "M月d日"
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.dateFormat = "MMM d"
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: dayData.date)
    }

    private func getLocalizedText(_ chinese: String, _ english: String) -> String {
        return localizationManager.currentLanguage == "zh-Hans" ? chinese : english
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = TimeEntryViewModel(bambooHRService: service)
    return TimesheetView(viewModel: viewModel)
}
