//
//  HomeView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: UserViewModel
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
                .padding()
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
            .refreshable {
                await refreshData()
            }
        }
        .onAppear {
            if viewModel.user == nil && !viewModel.isLoading {
                viewModel.loadUserInfo()
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
                    value: calculateWeeklyHours(),
                    icon: "clock.fill",
                    color: .blue,
                    subtitle: weeklyHoursSubtitle
                )

                StatCard(
                    title: localizationManager.localized(.homeRemainingLeave),
                    value: calculateRemainingLeave(),
                    icon: "beach.umbrella",
                    color: .orange,
                    subtitle: localizationManager.localized(.homeLeaveBalance)
                )

                StatCard(
                    title: localizationManager.localized(.homeMonthlyProjects),
                    value: calculateActiveProjects(),
                    icon: "folder.fill",
                    color: .purple,
                    subtitle: localizationManager.localized(.homeInProgress)
                )

                StatCard(
                    title: localizationManager.localized(.homeTeamSize),
                    value: calculateTeamSize(department: user.department),
                    icon: "person.3.fill",
                    color: .green,
                    subtitle: localizationManager.localized(.homeDepartmentMembers)
                )
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
                    value: localizationManager.localized(.homeWorkStatusActive),
                    valueColor: .green,
                    description: localizationManager.localized(.homeWorkStatusStarted)
                )

                QuickInfoRow(
                    icon: "person.2.badge.minus",
                    title: localizationManager.localized(.homeOnLeave),
                    value: "\(getTodayLeaveCount()) \(localizationManager.localized(.homePeople))",
                    valueColor: .orange,
                    description: localizationManager.localized(.homeViewDetails)
                )

                QuickInfoRow(
                    icon: "checkmark.circle",
                    title: localizationManager.localized(.homeTodayTasks),
                    value: "6/8",
                    valueColor: .blue,
                    description: localizationManager.localized(.homeTasksCompleted)
                )
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

    private var currentTimeIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "sun.max.fill"
        case 12..<17:
            return "sun.max.fill"
        case 17..<22:
            return "moon.fill"
        default:
            return "moon.stars.fill"
        }
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        if localizationManager.currentLanguage == "zh-Hans" {
            formatter.dateFormat = "M月d日 EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.dateFormat = "MMM d, EEEE"
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: Date())
    }

    private func getLocalizedText(_ chinese: String, _ english: String) -> String {
        return localizationManager.currentLanguage == "zh-Hans" ? chinese : english
    }

    // MARK: - Real Data Calculations
    private func calculateWeeklyHours() -> String {
        // In a real app, this would fetch from time entries
        let currentHour = Calendar.current.component(.hour, from: Date())
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())

        // Simulate worked hours based on current time and day
        let dailyHours = max(0, min(8, currentHour - 9))
        let weeklyHours = Double(dailyHours) + Double((dayOfWeek - 2) * 8)

        return String(format: "%.1f", max(0, weeklyHours))
    }

    private var weeklyHoursSubtitle: String {
        let worked = Double(calculateWeeklyHours()) ?? 0
        let target = 40.0
        let remaining = max(0, target - worked)

        if remaining > 0 {
            return "\(localizationManager.localized(.homeStillNeed)) \(String(format: "%.1f", remaining))\(localizationManager.localized(.homeHours))"
        } else {
            return getLocalizedText("本周已完成", "Week completed")
        }
    }

    private func calculateRemainingLeave() -> String {
        // In a real app, this would fetch from user's leave balance
        let startOfYear = Calendar.current.dateInterval(of: .year, for: Date())?.start ?? Date()
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startOfYear, to: Date()).day ?? 0

        // Simulate leave usage (assume 20 days annual leave, some used)
        let usedDays = min(20, daysSinceStart / 15) // Rough calculation
        let remaining = max(0, 20 - usedDays)

        return "\(remaining)"
    }

    private func calculateActiveProjects() -> String {
        // In a real app, this would fetch from projects API
        // Simulate based on user department
        return "3"
    }

    private func calculateTeamSize(department: String) -> String {
        // Simulate team size based on department
        switch department.lowercased() {
        case "engineering", "开发":
            return "12"
        case "design", "设计":
            return "8"
        case "marketing", "市场":
            return "15"
        case "sales", "销售":
            return "20"
        default:
            return "10"
        }
    }

    private func getTodayLeaveCount() -> Int {
        // In a real app, this would fetch from leave API
        // Simulate leave count
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        return dayOfWeek == 1 || dayOfWeek == 7 ? 0 : Int.random(in: 0...3)
    }

    private func refreshData() async {
        isRefreshing = true
        viewModel.loadUserInfo()
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
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
    }
}

// MARK: - Quick Info Row
struct QuickInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    let description: String

    var body: some View {
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
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = UserViewModel(bambooHRService: service)
    return HomeView(viewModel: viewModel)
}
