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
    @Binding var selectedTab: Int
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.error {
                        errorView(message: error)
                    } else if let user = viewModel.user {
                        userProfileSection(user: user)
                        quickStatsSection(user: user)
                        todayOverviewSection
                    } else {
                        noDataView
                    }
                }
                .padding(.horizontal) // 只保留水平padding
                .padding(.bottom) // 只保留底部padding
            }
            .contentMargins(.top, 0) // 移除顶部内容边距
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
            .refreshable {
                await refreshData()
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
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)

            Text(localizationManager.localized(.loadingUserInfo))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
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
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text(localizationManager.localized(.loadingFailed))
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button(localizationManager.localized(.retry)) {
                viewModel.loadUserInfo()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
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
                    value: String(format: "%.1f", viewModel.weeklyHours),
                    icon: "clock.fill",
                    color: .blue,
                    subtitle: getWeeklyHoursSubtitle(worked: viewModel.weeklyHours)
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
                    value: viewModel.isOnLeaveToday ?
                        getLocalizedText("休假中", "On Leave") :
                        localizationManager.localized(.homeWorkStatusActive),
                    valueColor: viewModel.isOnLeaveToday ? .orange : .green,
                    description: viewModel.isOnLeaveToday ?
                        getLocalizedText("今日休假", "On leave today") :
                        localizationManager.localized(.homeWorkStatusStarted)
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
        // Add subtle scale effect for actionable cards
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

#Preview {
    let service = BambooHRService()
    let viewModel = UserViewModel(bambooHRService: service)
    let leaveViewModel = LeaveViewModel(bambooHRService: service)
    return HomeView(viewModel: viewModel, leaveViewModel: leaveViewModel, selectedTab: .constant(0))
}
