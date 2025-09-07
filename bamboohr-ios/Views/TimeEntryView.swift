//
//  TimeEntryView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct TimeEntryView: View {
    @ObservedObject var viewModel: TimeEntryViewModel
    @Binding var selectedTab: Int
    @StateObject private var localizationManager = LocalizationManager.shared
    @FocusState private var isTextFieldFocused: Bool

    // Collapsible sections state
    @State private var showTodaysRecords = false
    @State private var showAnalytics = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 🎯 MAIN FOCUS: Quick Time Entry (Always at top)
                    quickTimeEntrySection

                    // 📊 Today's Summary (Compact overview)
                    todaysSummarySection

                    // 📋 Today's Records (Collapsible)
                    todaysRecordsSection

                    // 📈 Analytics & Reports (Collapsible, less prominent)
                    analyticsSection

                    // 📋 My Timesheet
                    monthlyTimesheetSummary
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .contentMargins(.top, -10)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        if let tabInfo = FloatingNavigationBar.getTabInfo(for: selectedTab) {
                            Image(systemName: tabInfo.activeIcon)
                                .foregroundColor(tabInfo.color)
                        } else {
                            Image(systemName: "clock.circle.fill")
                                .foregroundColor(.purple)
                        }
                        Text(localizationManager.localized(.timeTitle))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring()) {
                            viewModel.selectedDate = Date()
                        }
                        // 确保数据加载
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.forceRefreshTimeEntries()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.circle.fill")
                            Text(localizationManager.localized(.timeToday))
                        }
                    }
                    .navigationGradientButtonStyle(color: .purple)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    // Refresh button
                    Button {
                        viewModel.loadProjects()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .navigationGradientButtonStyle(color: .purple)
                    .disabled(viewModel.isLoading || viewModel.isSubmitting)
                }
            }
            .onTapGesture {
                // 点击空白处收起键盘
                hideKeyboard()
            }
            .gesture(
                // 拖拽手势也收起键盘
                DragGesture().onChanged { _ in
                    hideKeyboard()
                }
            )
        }
        .onAppear {
            if viewModel.projects.isEmpty && !viewModel.isLoading {
                viewModel.loadProjects()
            }
            viewModel.loadTimeEntries()
        }
    }

    // 键盘收起函数
    private func hideKeyboard() {
        isTextFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Quick Time Entry Section (Main Focus)
    private var quickTimeEntrySection: some View {
        VStack(spacing: 16) {
            // Header with date selection
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Worked Time")
                        .font(.headline)
                        .fontWeight(.bold)

                    DatePicker(
                        "",
                        selection: $viewModel.selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                    .onChange(of: viewModel.selectedDate) { oldValue, newValue in
                        if !Calendar.current.isDate(oldValue, inSameDayAs: newValue) {
                            viewModel.forceRefreshTimeEntries()
                        }
                    }
                }

                Spacer()

            }


            // Compact form in horizontal layout for quick entry
            VStack(spacing: 12) {
                // Hours and Project in one row
                HStack(spacing: 12) {
                    // Hours selector (compact)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localized(.timeDuration))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Button {
                                if viewModel.hours > 0.5 {
                                    viewModel.hours -= 0.5
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(viewModel.hours <= 0.5 ? .gray : .red)
                                    .font(.title3)
                            }
                            .disabled(viewModel.hours <= 0.5)

                            Text("\(String(format: "%.1f", viewModel.hours))h")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(minWidth: 50)

                            Button {
                                if viewModel.hours < 24.0 {
                                    viewModel.hours += 0.5
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(viewModel.hours >= 24.0 ? .gray : .green)
                                    .font(.title3)
                            }
                            .disabled(viewModel.hours >= 24.0)
                        }
                    }

                    // Project selector (compact)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localized(.timeProject))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text(localizationManager.localized(.loading))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if viewModel.projects.isEmpty {
                            Button(action: {
                                viewModel.loadProjects()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Load Projects")
                                }
                                .font(.caption)
                                .foregroundColor(.orange)
                            }
                        } else {
                            Picker("", selection: $viewModel.selectedProject) {
                                Text(localizationManager.localized(.timeSelectProject)).tag(nil as Project?)
                                ForEach(viewModel.projects, id: \.id) { project in
                                    Text(project.name).tag(project as Project?)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                // Task selector (if project selected)
                if let project = viewModel.selectedProject, !project.tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localized(.timeSelectTask))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("", selection: $viewModel.selectedTask) {
                            Text(localizationManager.localized(.timeSelectTask)).tag(nil as Task?)
                            ForEach(project.tasks, id: \.id) { task in
                                Text(task.name).tag(task as Task?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }
                    .transition(.opacity.combined(with: .scale))
                }

                // Notes (compact)
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localized(.timeNotes))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $viewModel.note)
                        .focused($isTextFieldFocused)
                        .frame(height: 60)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                // Submit button (prominent)
                Button(action: {
                    viewModel.submitTimeEntry()
                }) {
                    HStack {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(viewModel.isSubmitting ? localizationManager.localized(.timeSubmitting) : localizationManager.localized(.timeSubmit))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isSubmitting)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isSubmitting)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .purple.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Today's Summary Section
    private var todaysSummarySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recordsSectionTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if viewModel.isLoadingEntries {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Text("\(viewModel.formattedTotalHours) \(localizationManager.localized(.homeHours))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)

                    Text("\(viewModel.timeEntries.count) entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: {
                withAnimation(.spring()) {
                    showTodaysRecords.toggle()
                }
            }) {
                Image(systemName: showTodaysRecords ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }

    // MARK: - Today's Records Section (Collapsible)
    private var todaysRecordsSection: some View {
        VStack(spacing: 0) {
            if showTodaysRecords {
                VStack(spacing: 8) {
                    if viewModel.isLoadingEntries {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                ProgressView()
                                Text(getLocalizedText("正在加载...", "Loading..."))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .frame(minHeight: 60)
                    } else if viewModel.timeEntries.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.badge.xmark")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)

                            Text(localizationManager.localized(.timeNoRecords))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(8)
                    } else {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.timeEntries, id: \.id) { entry in
                                TimeEntryRowView(entry: entry)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showTodaysRecords)
    }

    // MARK: - Analytics Section (Collapsible)
    private var analyticsSection: some View {
        VStack(spacing: 12) {
            // Analytics header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.purple)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(getLocalizedText("分析报告", "Analytics & Reports"))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(getLocalizedText("查看工时统计", "View time statistics"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring()) {
                        showAnalytics.toggle()
                    }
                }) {
                    Image(systemName: showAnalytics ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.purple)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.5))
            )

            if showAnalytics {
                VStack(spacing: 12) {
                    // Weekly chart
                    weeklyTimeChart
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showAnalytics)
    }

    // MARK: - Legacy Records Section (keeping for reference)
    private var todayRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(recordsSectionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if viewModel.isLoadingEntries {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(localizationManager.localized(.timeTotalHours))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.formattedTotalHours) \(localizationManager.localized(.homeHours))")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                }
            }

            // 时间记录列表 - 添加加载状态和动画
            Group {
                if viewModel.isLoadingEntries {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(getLocalizedText("正在加载...", "Loading..."))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formattedDate)
                                .font(.caption2)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    .frame(minHeight: 80)
                    .transition(.opacity.combined(with: .scale))
                } else if viewModel.timeEntries.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)

                        Text(localizationManager.localized(.timeNoRecords))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Text(formattedDate)
                            .font(.caption)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .scale))
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.timeEntries, id: \.id) { entry in
                            TimeEntryRowView(entry: entry)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: viewModel.timeEntries.count)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoadingEntries)
            .animation(.easeInOut(duration: 0.3), value: viewModel.selectedDate)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    // Helper to generate dynamic records section title
    private var recordsSectionTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(viewModel.selectedDate) {
            return localizationManager.localized(.timeTodayRecords)
        } else {
            return localizationManager.localized(.timeRecordsFor)
        }
    }


    // MARK: - Legacy sections removed - functionality moved to quickTimeEntrySection

    private var formattedDate: String {
        let formatter = DateFormatter()
        if localizationManager.currentLanguage == "zh-Hans" {
            formatter.dateFormat = "M月d日 EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.dateFormat = "MMM d, EEEE"
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: viewModel.selectedDate)
    }

    private func getLocalizedText(_ chinese: String, _ english: String) -> String {
        return localizationManager.currentLanguage == "zh-Hans" ? chinese : english
    }
}

// MARK: - Time Entry Row View
struct TimeEntryRowView: View {
    let entry: TimeEntry
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if let projectName = entry.projectName {
                    Text(projectName)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                if let taskName = entry.taskName {
                    Text(taskName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(String(format: "%.1f", entry.hours))h")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)

                Text(localizationManager.localized(.timeSubmitted))
                    .font(.caption2)
                    .foregroundColor(.green)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - 周柱状图组件
extension TimeEntryView {
    private var weeklyTimeChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(localizationManager.localized(.timeWeeklyWorkHours), systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundColor(.primary)

            WeeklyTimeChartView(selectedDate: viewModel.selectedDate, viewModel: viewModel)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var monthlyTimesheetSummary: some View {
        NavigationLink(destination: TimesheetView(viewModel: viewModel)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.purple)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(getLocalizedText("我的工时表", "My Timesheet"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(getLocalizedText("查看本月工时详情", "View monthly time details"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(getLocalizedText("本月总计", "Month Total"))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Text(currentMonthHours)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)

                            Text(getLocalizedText("小时", "hours"))
                                .font(.caption)
                                .foregroundColor(.purple)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var currentMonthHours: String {
        return String(format: "%.1f", viewModel.currentMonthTotalHours)
    }
}

// MARK: - 周柱状图具体实现
struct WeeklyTimeChartView: View {
    let selectedDate: Date
    @ObservedObject var viewModel: TimeEntryViewModel
    @State private var weeklyData: [DayTimeData] = []
    @State private var showingTooltip: String? = nil
    @State private var tooltipPosition: CGPoint = .zero

    var body: some View {
        VStack(spacing: 12) {
            // 图表
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData, id: \.date) { dayData in
                    VStack(spacing: 4) {
                        // 柱状条
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dayData.isToday ? Color.purple : Color.purple.opacity(0.7))
                            .frame(width: 35, height: max(4, dayData.height))
                            .overlay(
                                // 点击区域
                                Rectangle()
                                    .fill(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture { location in
                                        showTooltip(for: dayData, at: location)
                                    }
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                showTooltip(for: dayData, at: value.location)
                                            }
                                            .onEnded { _ in
                                                hideTooltip()
                                            }
                                    )
                            )

                        // 日期标签
                        Text(dayData.dayLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fontWeight(dayData.isToday ? .bold : .regular)
                    }
                }
            }
            .frame(height: 120)

            // 底部说明
            HStack {
                Text("0h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                let localizationManager = LocalizationManager.shared
                let maxText = localizationManager.currentLanguage == "zh-Hans" ? "最高" : "Max"
                Text("\(maxText): \(String(format: "%.1f", maxHours))h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .overlay(
            // Tooltip
            tooltipView
        )
        .onAppear {
            loadWeeklyData()
        }
        .onChange(of: selectedDate) { _, _ in
            loadWeeklyData()
        }
        .onChange(of: viewModel.weeklyTimeEntries) { _, _ in
            // 当本周缓存数据更新时重新加载图表数据
            loadWeeklyData()
        }
    }

    // Tooltip视图
    @ViewBuilder
    private var tooltipView: some View {
        if let tooltipText = showingTooltip {
            Text(tooltipText)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(6)
                .position(tooltipPosition)
                .zIndex(1)
        }
    }

    // 显示tooltip
    private func showTooltip(for dayData: DayTimeData, at location: CGPoint) {
        let localizationManager = LocalizationManager.shared
        let hoursText = localizationManager.currentLanguage == "zh-Hans" ? "小时" : "hours"
        showingTooltip = "\(dayData.dayLabel): \(String(format: "%.1f", dayData.hours))\(hoursText)"
        tooltipPosition = CGPoint(x: location.x, y: location.y - 30)

        // 自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            hideTooltip()
        }
    }

    // 隐藏tooltip
    private func hideTooltip() {
        showingTooltip = nil
    }

    // 计算最大小时数
    private var maxHours: Double {
        weeklyData.map { $0.hours }.max() ?? 8.0
    }

    // 加载周数据
    private func loadWeeklyData() {
        // 从ViewModel获取本周的真实数据
        var data = viewModel.getWeeklyTimeData(for: selectedDate)

        // 重新计算高度
        let maxHours = data.map { $0.hours }.max() ?? 8.0

        for i in 0..<data.count {
            data[i] = DayTimeData(
                date: data[i].date,
                hours: data[i].hours,
                dayLabel: data[i].dayLabel,
                isToday: data[i].isToday,
                height: calculateHeight(hours: data[i].hours, maxHours: maxHours)
            )
        }

        weeklyData = data
    }

    // 计算柱状图高度
    private func calculateHeight(hours: Double, maxHours: Double) -> CGFloat {
        let maxHeight: CGFloat = 100
        guard maxHours > 0 else { return 4 }
        return max(4, CGFloat(hours / maxHours) * maxHeight)
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = TimeEntryViewModel(bambooHRService: service)
    return TimeEntryView(viewModel: viewModel, selectedTab: .constant(1))
}
