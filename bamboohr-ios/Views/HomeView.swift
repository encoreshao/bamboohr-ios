//
//  HomeView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: UserViewModel
    @ObservedObject var leaveViewModel: LeaveViewModel
    @ObservedObject var timeEntryViewModel: TimeEntryViewModel
    @Binding var selectedTab: Int
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(message: error)
                } else if let user = viewModel.user {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            userProfileSection(user: user)
                            quickStatsSection(user: user)
                            myTimeOffRequestsSection
                            todayOverviewSection
                        }
                        .padding(.horizontal) // 只保留水平padding
                        .padding(.bottom) // 只保留底部padding
                    }
                    .contentMargins(.top, 0) // 移除顶部内容边距
                    .refreshable {
                        await refreshData()
                    }
                } else {
                    noDataView
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .foregroundColor(.blue)
                        Text(localizationManager.localized(.homeTitle))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.loadUserInfo()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .onAppear {
            if viewModel.user == nil && !viewModel.isLoading {
                viewModel.loadUserInfo()
            }

            // 确保休假数据也加载
            if leaveViewModel.leaveEntries.isEmpty && !leaveViewModel.isLoading {
                leaveViewModel.loadLeaveInfo()
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                // Loading animation
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.8)
                        .tint(.blue)

                    // Animated dots
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(.blue)
                                .frame(width: 6, height: 6)
                                .opacity(0.3)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: true
                                )
                        }
                    }
                }

                VStack(spacing: 8) {
                    Text(localizationManager.localized(.homeLoadingProfile))
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(localizationManager.localized(.peoplePleaseWait))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - No Data View
    private var noDataView: some View {
        ContentUnavailableView {
            Label(localizationManager.localized(.userInfoUnavailable), systemImage: "person.crop.circle.badge.exclamationmark")
        } description: {
            Text(localizationManager.localized(.checkSettings))
        } actions: {
            Button(localizationManager.localized(.refresh)) {
                viewModel.loadUserInfo()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        GeometryReader { geometry in
            VStack(spacing: 32) {
                // Error illustration
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.1), .red.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "wifi.slash")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 12) {
                        Text(localizationManager.localized(.loadingFailed))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(message)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .padding(.horizontal, 20)
                    }
                }

                // Retry button with better styling
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.loadUserInfo()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(localizationManager.localized(.retry))
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: true)
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - User Profile Section
    private func userProfileSection(user: User) -> some View {
        VStack(spacing: 16) {
            // Avatar and Basic Info
            HStack(spacing: 16) {
                // Avatar
                AvatarView(name: user.fullName, photoUrl: user.photoUrl, size: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )

                // User Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(user.fullName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(user.jobTitle)
                        .font(.headline)
                        .foregroundColor(.blue)

                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(user.department)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Image(systemName: "map.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(user.location!)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Welcome Message
            welcomeMessage
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }

    private var welcomeMessage: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingMessage)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(localizationManager.localized(.homeGreetingSubtitle))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: currentTimeIcon)
                .font(.title)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Quick Stats Section
    private func quickStatsSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.green)
                Text(localizationManager.localized(.homeQuickStats))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: localizationManager.localized(.homeWeeklyWork),
                    value: String(format: "%.1f", getCurrentWeeklyHours()),
                    icon: "clock.fill",
                    color: .blue,
                    subtitle: getWeeklyHoursSubtitle(worked: getCurrentWeeklyHours())
                )

                StatCard(
                    title: localizationManager.localized(.homeRemainingLeave),
                    value: "\(viewModel.remainingLeavedays)",
                    icon: "beach.umbrella",
                    color: .orange,
                    subtitle: localizationManager.localized(.homeLeaveBalance)
                )

                StatCard(
                    title: localizationManager.localized(.homeMonthlyProjects),
                    value: "\(viewModel.totalProjects)",
                    icon: "folder.fill",
                    color: .purple,
                    subtitle: localizationManager.localized(.homeInProgress)
                )

                StatCard(
                    title: localizationManager.localized(.homeTeamSize),
                    value: "\(viewModel.totalEmployees)",
                    icon: "person.3.fill",
                    color: .green,
                    subtitle: localizationManager.localized(.homeDepartmentMembers)
                ) {
                    // 点击跳转到People页面
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = 3
                    }
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

    // MARK: - Today Overview Section
    private var todayOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.blue)
                Text(localizationManager.localized(.homeTodayOverview))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(todayDateString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                QuickInfoRow(
                    icon: "clock.arrow.circlepath",
                    title: localizationManager.localized(.homeWorkStatus),
                    value: getWorkStatusText(),
                    valueColor: getWorkStatusColor(),
                    description: getWorkStatusDescription()
                )

                QuickInfoRow(
                    icon: "person.2.badge.minus",
                    title: localizationManager.localized(.homeOnLeave),
                    value: "\(getTodayLeaveCount()) \(localizationManager.localized(.homePeople))",
                    valueColor: .orange,
                    description: localizationManager.localized(.homeViewDetails)
                ) {
                    // 点击跳转到休假页面
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = 2
                    }
                }

                // 删除今日任务行，因为没有真实数据
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Helper Methods

    // 过滤当前用户的休假记录
    private var myLeaveEntries: [BambooLeaveInfo] {
        guard let user = viewModel.user, let currentUserId = Int(user.id) else {
            return []
        }
        return leaveViewModel.leaveEntries.filter { entry in
            entry.employeeId == currentUserId
        }
    }

    // 计算今天的休假人数（与LeaveView保持一致）
    private func getTodayLeaveCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return leaveViewModel.leaveEntries.filter { entry in
            guard let start = entry.startDate, let end = entry.endDate else { return false }
            return (start...end).contains(today)
        }.count
    }

    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return localizationManager.localized(.homeGreetingMorning)
        case 12..<17:
            return localizationManager.localized(.homeGreetingAfternoon)
        case 17..<22:
            return localizationManager.localized(.homeGreetingEvening)
        default:
            return localizationManager.localized(.homeGreetingNight)
        }
    }

    private func getWeeklyHoursSubtitle(worked: Double) -> String {
        let target = 40.0
        let remaining = max(0, target - worked)

        if remaining > 0 {
            return "\(localizationManager.localized(.homeStillNeed)) \(String(format: "%.1f", remaining))\(localizationManager.localized(.homeHours))"
        } else {
            return getLocalizedText("本周已完成", "Week completed")
        }
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }

    private var currentTimeIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return "sun.and.horizon"
        case 12..<18:
            return "sun.max"
        case 18..<21:
            return "sun.haze"
        default:
            return "moon.stars"
        }
    }

    private func getLocalizedText(_ chinese: String, _ english: String) -> String {
        return localizationManager.currentLanguage == "zh-Hans" ? chinese : english
    }

    private func refreshData() async {
        isRefreshing = true
        viewModel.loadUserInfo()
        leaveViewModel.loadLeaveInfo()
        isRefreshing = false
    }

    // MARK: - Helper Methods

    private func getCurrentWeeklyHours() -> Double {
        let weeklyData = timeEntryViewModel.getWeeklyTimeData(for: Date())
        return weeklyData.reduce(0.0) { $0 + $1.hours }
    }

    private func getWorkStatusText() -> String {
        if viewModel.isOnLeaveToday {
            return getLocalizedText("休假中", "On Leave")
        }

        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)

        // Check if today is weekend (Saturday = 7, Sunday = 1)
        if weekday == 1 || weekday == 7 {
            return getLocalizedText("周末", "Weekend")
        }

        return localizationManager.localized(.homeWorkStatusActive)
    }

    private func getWorkStatusColor() -> Color {
        if viewModel.isOnLeaveToday {
            return .orange
        }

        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)

        // Weekend color
        if weekday == 1 || weekday == 7 {
            return .gray
        }

        return .green
    }

    private func getWorkStatusDescription() -> String {
        if viewModel.isOnLeaveToday {
            return getLocalizedText("今日休假", "On leave today")
        }

        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)

        // Check if today is weekend
        if weekday == 1 || weekday == 7 {
            return getLocalizedText("今日为周末", "Today is weekend")
        }

        return localizationManager.localized(.homeWorkStatusStarted)
    }

    // MARK: - My Time Off Requests Section

    private var myTimeOffRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.purple)
                Text(getLocalizedText("我的休假申请", "My Time Off Requests"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if myLeaveEntries.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.6))

                    Text(getLocalizedText("暂无休假记录", "No time off requests"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            } else {
                // Show recent requests (limit to 3)
                VStack(spacing: 8) {
                    ForEach(Array(myLeaveEntries.prefix(3)), id: \.id) { request in
                        TimeOffRequestRow(request: request)
                    }

                    if myLeaveEntries.count > 3 {
                        Button(action: {
                            // Navigate to Leave tab
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = 2
                            }
                        }) {
                            HStack {
                                Text(getLocalizedText("查看更多", "View More"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Image(systemName: "chevron.right")
                                    .font(.caption)

                                Spacer()

                                Text("(\(myLeaveEntries.count - 3) more)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
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
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    let action: (() -> Void)?

    init(title: String, value: String, icon: String, color: Color, subtitle: String, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    statCardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                statCardContent
            }
        }
    }

    private var statCardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()

                // Show chevron for actionable cards
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.leading, 4)
                }
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(action != nil ? 1.0 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: action != nil)
    }
}

// MARK: - Quick Info Row
struct QuickInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    let description: String
    let action: (() -> Void)?

    init(icon: String, title: String, value: String, valueColor: Color, description: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.valueColor = valueColor
        self.description = description
        self.action = action
    }

    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    quickInfoContent
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            } else {
                quickInfoContent
            }
        }
    }

    private var quickInfoContent: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(valueColor)

            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.leading, 4)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, action != nil ? 8 : 0)
    }
}

// MARK: - Time Off Request Row Component
struct TimeOffRequestRow: View {
    let request: BambooLeaveInfo

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(request.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(dateRangeText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(request.type)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(statusColor.opacity(0.15))
                        )
                        .foregroundColor(statusColor)

                    Spacer()

                    if let duration = request.leaveDuration {
                        Text("\(duration) day\(duration > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }

    private var statusColor: Color {
        // You can customize this based on request status
        return .blue
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short

        if let start = request.startDate, let end = request.endDate {
            let startStr = formatter.string(from: start)
            let endStr = formatter.string(from: end)

            if Calendar.current.isDate(start, inSameDayAs: end) {
                return startStr
            } else {
                return "\(startStr) - \(endStr)"
            }
        }

        return "Unknown"
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = UserViewModel(bambooHRService: service)
    let leaveViewModel = LeaveViewModel(bambooHRService: service)
    let timeEntryViewModel = TimeEntryViewModel(bambooHRService: service)
    return HomeView(viewModel: viewModel, leaveViewModel: leaveViewModel, timeEntryViewModel: timeEntryViewModel, selectedTab: .constant(0))
}
