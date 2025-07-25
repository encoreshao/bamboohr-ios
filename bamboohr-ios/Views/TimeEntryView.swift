//
//  TimeEntryView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct TimeEntryView: View {
    @ObservedObject var viewModel: TimeEntryViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingDatePicker = false
    @FocusState private var isTextFieldFocused: Bool // 添加键盘焦点状态管理

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current date records section
                    todayRecordsSection

                    // Time entry form
                    timeEntryForm

                    // 添加周柱状图
                    weeklyTimeChart
                }
                .padding(.horizontal) // 减少顶部padding
                .padding(.bottom) // 只保留底部padding
            }
            .contentMargins(.top, 0) // 移除顶部内容边距
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.circle.fill")
                            .foregroundColor(.blue)
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
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.circle.fill")
                                .foregroundColor(.blue)
                            Text(localizationManager.localized(.timeToday))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.loadProjects()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
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

    // MARK: - Records Section
    private var todayRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.circle.fill")
                    .foregroundColor(.blue)
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
                            .foregroundColor(.blue)
                    }
                }
            }

            if viewModel.timeEntries.isEmpty && !viewModel.isLoadingEntries {
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(localizationManager.localized(.timeNoRecords))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                LazyVStack(spacing: 6) {
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

    // MARK: - Time Entry Form
    private var timeEntryForm: some View {
        VStack(spacing: 20) {
            // Date Selection
            dateSelectionSection

            // Hours Input
            hoursInputSection

            // Project and Task Selection
            projectSelectionSection

            // Notes Input
            notesSection

            // Submit Button
            submitButton
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(localizationManager.localized(.timeSelectDate), systemImage: "calendar")
                .font(.headline)
                .foregroundColor(.primary)

            Button(action: {
                withAnimation(.spring()) {
                    showingDatePicker.toggle()
                }
            }) {
                HStack {
                    Text(formattedDate)
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: showingDatePicker ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            if showingDatePicker {
                DatePicker(
                    localizationManager.localized(.timeSelectDate),
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .labelsHidden()
                .transition(.opacity.combined(with: .scale))
            }
        }
    }

    private var hoursInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localizationManager.localized(.timeWorkDuration), systemImage: "clock")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                HStack {
                    Text(localizationManager.localized(.timeDuration))
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            if viewModel.hours > 0.5 {
                                viewModel.hours -= 0.5
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(viewModel.hours <= 0.5 ? .gray : .red)
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.hours <= 0.5)

                        Text("\(String(format: "%.1f", viewModel.hours)) \(localizationManager.localized(.homeHours))")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(minWidth: 100)

                        Button {
                            if viewModel.hours < 24.0 {
                                viewModel.hours += 0.5
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(viewModel.hours >= 24.0 ? .gray : .green)
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.hours >= 24.0)
                    }
                }

                Slider(
                    value: $viewModel.hours,
                    in: 0.5...24.0,
                    step: 0.5
                ) {
                    Text(localizationManager.localized(.timeWorkDuration))
                } minimumValueLabel: {
                    Text("0.5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("24")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .tint(.blue)
            }
        }
    }

    private var projectSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(localizationManager.localized(.timeProject), systemImage: "folder")
                .font(.headline)
                .foregroundColor(.primary)

            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(localizationManager.localized(.loading))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if viewModel.projects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    Text(localizationManager.localized(.timeNoProjects))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    // Project Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("", selection: $viewModel.selectedProject) {
                            Text(localizationManager.localized(.timeSelectProject)).tag(nil as Project?)
                            ForEach(viewModel.projects, id: \.id) { project in
                                HStack {
                                    Text(project.name)
                                    Spacer()
                                    if !project.tasks.isEmpty {
                                        Text("\(project.tasks.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                                .tag(project as Project?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity)
                    }

                    // Task Selection (if available)
                    if let project = viewModel.selectedProject, !project.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("", selection: $viewModel.selectedTask) {
                                Text(localizationManager.localized(.timeSelectTask)).tag(nil as Task?)
                                ForEach(project.tasks, id: \.id) { task in
                                    Text(task.name).tag(task as Task?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                        }
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedProject?.id)
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(localizationManager.localized(.timeNotes), systemImage: "text.alignleft")
                .font(.headline)
                .foregroundColor(.primary)

            TextEditor(text: $viewModel.note)
                .focused($isTextFieldFocused) // 添加焦点状态绑定
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }

    private var submitButton: some View {
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
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.isSubmitting ? Color.gray : Color.blue)
            )
        }
        .disabled(viewModel.isSubmitting)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSubmitting)
    }

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
                    .foregroundColor(.blue)

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
            Label("本周工作时长", systemImage: "chart.bar.fill")
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
                            .fill(dayData.isToday ? Color.blue : Color.blue.opacity(0.7))
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
                Text("最高: \(String(format: "%.1f", maxHours))h")
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
        showingTooltip = "\(dayData.dayLabel): \(String(format: "%.1f", dayData.hours))小时"
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
        let calendar = Calendar.current
        let today = Date()

        // 获取本周的开始日期(周一)
        let weekday = calendar.component(.weekday, from: selectedDate)
        // let /*daysFromMonday*/ = (weekday == 1) ? 6 : weekday - 2 // 周日是1，周一是2
        let daysFromMonday = weekday;
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate) else { return }

        var data: [DayTimeData] = []

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }

            // 模拟数据 - 实际应该从viewModel或API获取
            let hours = generateMockHours(for: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)

            let dayData = DayTimeData(
                date: date,
                hours: hours,
                dayLabel: formatDayLabel(date),
                isToday: isToday,
                height: calculateHeight(hours: hours)
            )

            data.append(dayData)
        }

        weeklyData = data
    }

    // 生成模拟数据
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

    // 格式化日期标签
    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // 周几的简写
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    // 计算柱状图高度
    private func calculateHeight(hours: Double) -> CGFloat {
        let maxHeight: CGFloat = 100
        let maxHours = self.maxHours
        return CGFloat(hours / maxHours) * maxHeight
    }
}

// MARK: - 周数据模型
struct DayTimeData {
    let date: Date
    let hours: Double
    let dayLabel: String
    let isToday: Bool
    let height: CGFloat
}

#Preview {
    let service = BambooHRService()
    let viewModel = TimeEntryViewModel(bambooHRService: service)
    return TimeEntryView(viewModel: viewModel)
}
