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
    @StateObject private var celebrationViewModel: CelebrationViewModel
    @State private var isRefreshing = false
    @State private var hasAppeared = false

    init(viewModel: UserViewModel, leaveViewModel: LeaveViewModel, timeEntryViewModel: TimeEntryViewModel, selectedTab: Binding<Int>) {
        self.viewModel = viewModel
        self.leaveViewModel = leaveViewModel
        self.timeEntryViewModel = timeEntryViewModel
        self._selectedTab = selectedTab
        self._celebrationViewModel = StateObject(wrappedValue: CelebrationViewModel(bambooHRService: BambooHRService.shared))
    }

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
                            // 🎯 Combined Profile & Today Overview Section
                            combinedProfileOverviewSection(user: user)
                                .scaleIn(delay: 0.05, initialScale: 0.9)
                                .slideIn(from: .top, distance: 30, delay: 0.05)

                            // 🏖️ Leave Balance Header
                            leaveBalanceHeader
                                .fadeIn(delay: 0.1)

                            // Celebrations section
                            CelebrationsSection(viewModel: celebrationViewModel)
                                .scaleIn(delay: 0.3, initialScale: 0.9)
                                .slideIn(from: .trailing, distance: 40, delay: 0.3)

                            myTimeOffRequestsSection
                                .scaleIn(delay: 0.5, initialScale: 0.9)
                                .slideIn(from: .bottom, distance: 30, delay: 0.5)
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
                        if let tabInfo = FloatingNavigationBar.getTabInfo(for: selectedTab) {
                            Image(systemName: tabInfo.activeIcon)
                                .foregroundColor(tabInfo.color)
                        } else {
                            Image(systemName: "house.fill")
                                .foregroundColor(.blue)
                        }
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
                    }
                    .navigationGradientButtonStyle(color: .blue)
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                if viewModel.user == nil && !viewModel.isLoading {
                    viewModel.loadUserInfo()
                }

                // 确保休假数据也加载
                if leaveViewModel.leaveEntries.isEmpty && !leaveViewModel.isLoading {
                    leaveViewModel.loadLeaveInfo()
                }
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
            .primaryGradientButtonStyle()
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
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                }
                .primaryGradientButtonStyle()
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Combined Profile & Today Overview Section
    private func combinedProfileOverviewSection(user: User) -> some View {
        VStack(spacing: 20) {
            // Top section: Profile + Time-based greeting
            VStack(spacing: 16) {
                // Profile Header with Time Info
                HStack(spacing: 16) {
                    // Avatar with enhanced styling
                    AvatarView(name: user.fullName, photoUrl: user.photoUrl, size: 80)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: getTimeGradientColors(),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: getTimeGradientColors().first?.opacity(0.3) ?? .blue.opacity(0.3), radius: 8, x: 0, y: 4)

                    // User Info + Time Greeting
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

                            if let location = user.location {
                                Image(systemName: "map.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(location)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Time & Status Info
                    VStack(alignment: .trailing, spacing: 4) {
                        // Time-based icon with glow
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: getTimeGradientColors(),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .shadow(color: getTimeGradientColors().first?.opacity(0.4) ?? .blue.opacity(0.4), radius: 8, x: 0, y: 4)

                            Image(systemName: currentTimeIcon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .symbolEffect(.pulse.byLayer, options: .repeating)
                        }

                        Text(getCurrentTime())
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(getGreetingBasedOnTime())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                }

                // Welcome Message with Work Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greetingMessage)
                            .font(.headline)
                            .fontWeight(.semibold)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(getWorkStatusColor())
                                .frame(width: 8, height: 8)
                                .scaleEffect(1.2)
                                .shadow(color: getWorkStatusColor().opacity(0.6), radius: 4, x: 0, y: 2)

                            Text(getWorkStatusText())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(getWorkStatusColor())

                            Text("•")
                                .foregroundColor(.secondary)

                            Text(getFormattedDateWithDay())
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                        }
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(12)
            }

            // Creative Compact Stats Layout
            VStack(spacing: 12) {
                // Top Row: Weekly Hours (Primary Focus)
                creativeWeeklyHoursCard

                // Individual Leave Card
                fullWidthLeaveCard

                // Individual Team Card
                fullWidthTeamCard
            }
        }
        .padding()
        .background(
            ZStack {
                // Dynamic background based on time of day
                LinearGradient(
                    colors: getBackgroundGradientColors(),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle pattern overlay
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height

                        // Create subtle wave pattern
                        path.move(to: CGPoint(x: 0, y: height * 0.8))
                        path.addCurve(
                            to: CGPoint(x: width, y: height * 0.7),
                            control1: CGPoint(x: width * 0.3, y: height * 0.95),
                            control2: CGPoint(x: width * 0.7, y: height * 0.5)
                        )
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height))
                        path.closeSubpath()
                    }
                    .fill(Color.white.opacity(0.1))
                }
            }
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
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



    // MARK: - Leave Balance Header

    private var leaveBalanceHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "beach.umbrella.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.orange)

            Text(localizationManager.localized(.homePaidTimeOff))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("\(viewModel.remainingLeavedays) \(localizationManager.localized(.homeDaysRemaining))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Creative Compact Cards

    private var creativeWeeklyHoursCard: some View {
        HStack(spacing: 16) {
            // Left side: Circular progress indicator
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)

                // Progress circle
                Circle()
                    .trim(from: 0, to: min(getCurrentWeeklyHours() / 40.0, 1.0))
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: getCurrentWeeklyHours())

                // Center icon
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            // Right side: Stats and info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(localizationManager.localized(.homeWeeklyWork))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(String(format: "%.1f", getCurrentWeeklyHours()))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("h")
                        .font(.subheadline)
                        .foregroundColor(.blue.opacity(0.7))
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(getCurrentWeeklyHours() / 40.0, 1.0), height: 6)
                            .animation(.easeInOut(duration: 1.0), value: getCurrentWeeklyHours())
                    }
                }
                .frame(height: 6)

                Text(getWeeklyHoursSubtitle(worked: getCurrentWeeklyHours()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .blue.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var fullWidthLeaveCard: some View {
        Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                selectedTab = 2
            }
        }) {
            HStack(spacing: 16) {
                // Left: Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.2), .red.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.orange)
                }

                // Center: Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(getTodayLeaveCount())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Text(localizationManager.localized(.homeTeamMembersOnLeave))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    Text(localizationManager.localized(.homeTodayTapDetails))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Right: Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .orange.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.orange.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var fullWidthTeamCard: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = 3
            }
        }) {
            HStack(spacing: 16) {
                // Left: Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.2), .mint.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "person.3.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.green)
                }

                // Center: Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(viewModel.totalEmployees)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        Text(localizationManager.localized(.homeTotalTeamMembers))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    Text(localizationManager.localized(.homeCompanyDirectoryTap))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Right: Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .green.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.green.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }


    // MARK: - Helper Methods

    // 过滤当前用户的休假记录，只显示正在进行或未来的请求
    private var myLeaveEntries: [BambooLeaveInfo] {
        guard let user = viewModel.user, let currentUserId = Int(user.id) else {
            return []
        }
        let today = Calendar.current.startOfDay(for: Date())

        return leaveViewModel.leaveEntries
            .filter { entry in
                guard entry.employeeId == currentUserId else { return false }

                // 只显示正在进行中或未来的请求（结束日期在今天或之后）
                if let endDate = entry.endDate {
                    let endOfDay = Calendar.current.startOfDay(for: endDate)
                    return endOfDay >= today
                }

                // 如果没有结束日期信息，则保留该记录
                return true
            }
            .sorted { entry1, entry2 in
                // 按开始日期排序，最近的请求排在前面
                guard let start1 = entry1.startDate, let start2 = entry2.startDate else {
                    return false
                }
                return start1 < start2
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
            return localizationManager.localized(.homeWeekCompleted)
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

    // MARK: - Enhanced Helper Methods for New Design

    private func getTimeGradientColors() -> [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return [.orange, .yellow]  // Morning sunrise
        case 12..<17:
            return [.blue, .cyan]      // Afternoon sky
        case 17..<20:
            return [.orange, .red]     // Evening sunset
        default:
            return [.indigo, .purple]  // Night
        }
    }

    private func getBackgroundGradientColors() -> [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)]
        case 12..<17:
            return [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)]
        case 17..<20:
            return [Color.orange.opacity(0.1), Color.red.opacity(0.05)]
        default:
            return [Color.indigo.opacity(0.1), Color.purple.opacity(0.05)]
        }
    }

    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    private func getFormattedDateWithDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private func getGreetingBasedOnTime() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return getLocalizedText("早晨", "Morning")
        case 12..<17:
            return getLocalizedText("下午", "Afternoon")
        case 17..<20:
            return getLocalizedText("傍晚", "Evening")
        default:
            return getLocalizedText("夜晚", "Night")
        }
    }

    private func refreshData() async {
        isRefreshing = true
        viewModel.loadUserInfo()
        leaveViewModel.loadLeaveInfo()
        celebrationViewModel.loadCelebrations()
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
                // Creative empty state
                Button(action: {
                    // Navigate to Leave tab to create a request
                    HapticFeedback.light()
                    withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }) {
                    VStack(spacing: 16) {
                        // Animated icon stack
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.purple)
                                .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.8))
                        }

                        VStack(spacing: 6) {
                            Text(localizationManager.localized(.homeReadyTimeOff))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text(localizationManager.localized(.homeTapRequestVacation))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Call to action indicator
                        HStack(spacing: 6) {
                            Text(localizationManager.localized(.homeGetStarted))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)

                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: .purple.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Show recent requests (limit to 3)
                VStack(spacing: 8) {
                    ForEach(Array(myLeaveEntries.prefix(3)), id: \.id) { request in
                        TimeOffRequestRow(request: request, localizationManager: localizationManager)
                    }

                    if myLeaveEntries.count > 3 {
                        Button(action: {
                            // Navigate to Leave tab
                            HapticFeedback.light()
                            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7)) {
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
                .actionCardGradientStyle(color: color)
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
                .actionCardGradientStyle(color: .blue)
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
    let localizationManager: LocalizationManager

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

                    // Status label
                    Text(statusText)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor.opacity(0.1))
                        )
                        .foregroundColor(statusColor)

                    Spacer()

                    if let duration = request.leaveDuration {
                        Text("\(duration) \(duration > 1 ? localizationManager.localized(.homeDays) : localizationManager.localized(.homeDay))")
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
        let today = Calendar.current.startOfDay(for: Date())

        guard let startDate = request.startDate, let endDate = request.endDate else {
            return .gray
        }

        let startOfDay = Calendar.current.startOfDay(for: startDate)
        let endOfDay = Calendar.current.startOfDay(for: endDate)

        // Check if request is currently active (today is within the date range)
        if startOfDay <= today && endOfDay >= today {
            return .green  // Currently on leave
        }
        // Check if request is upcoming (starts in the future)
        else if startOfDay > today {
            return .blue   // Upcoming leave
        }
        // This should not happen since we filter out past requests, but just in case
        else {
            return .gray   // Past leave (should be filtered out)
        }
    }

    private var statusText: String {
        let today = Calendar.current.startOfDay(for: Date())

        guard let startDate = request.startDate, let endDate = request.endDate else {
            return localizationManager.localized(.homeUnknown)
        }

        let startOfDay = Calendar.current.startOfDay(for: startDate)
        let endOfDay = Calendar.current.startOfDay(for: endDate)

        // Check if request is currently active (today is within the date range)
        if startOfDay <= today && endOfDay >= today {
            return localizationManager.localized(.homeActive)
        }
        // Check if request is upcoming (starts in the future)
        else if startOfDay > today {
            return localizationManager.localized(.homeUpcoming)
        }
        // This should not happen since we filter out past requests, but just in case
        else {
            return localizationManager.localized(.homePast)
        }
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

        return localizationManager.localized(.homeUnknown)
    }
}

// MARK: - Enhanced Info Card Component
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let gradientColors: [Color]
    let iconBackground: Color
    let action: (() -> Void)?

    @State private var isPressed = false

    init(icon: String, title: String, value: String, subtitle: String, color: Color, gradientColors: [Color], iconBackground: Color, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.gradientColors = gradientColors
        self.iconBackground = iconBackground
        self.action = action
    }

    var body: some View {
        Button(action: {
            if let action = action {
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Icon with enhanced styling
                HStack {
                    ZStack {
                        Circle()
                            .fill(iconBackground)
                            .frame(width: 40, height: 40)
                            .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)

                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(color)
                            .symbolEffect(.bounce.byLayer, options: .nonRepeating, value: isPressed)
                    }

                    Spacer()

                    if action != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(color.opacity(0.6))
                            .fontWeight(.medium)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Value with gradient
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    // Title
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // Subtitle
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(20)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))

                    // Gradient border effect
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )

                    // Subtle inner glow
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.05), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: color.opacity(isPressed ? 0.3 : 0.15),
                radius: isPressed ? 8 : 12,
                x: 0,
                y: isPressed ? 4 : 6
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = UserViewModel(bambooHRService: service)
    let leaveViewModel = LeaveViewModel(bambooHRService: service)
    let timeEntryViewModel = TimeEntryViewModel(bambooHRService: service)
    return HomeView(viewModel: viewModel, leaveViewModel: leaveViewModel, timeEntryViewModel: timeEntryViewModel, selectedTab: .constant(0))
}
