//
//  LeaveView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct AuthenticatedAsyncImage: View {
    let url: URL
    let apiKey: String

    @State private var image: Image? = nil
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if loadFailed {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            } else {
                ProgressView()
                    .onAppear {
                        fetchImage()
                    }
            }
        }
    }

    private func fetchImage() {
        var request = URLRequest(url: url)
        let authString = "Basic " + "\(apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.setValue(authString, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = Image(uiImage: uiImage)
                }
            } else {
                DispatchQueue.main.async {
                    self.loadFailed = true
                }
            }
        }.resume()
    }
}

struct LeaveView: View {
    @ObservedObject var viewModel: LeaveViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.error {
                        errorView(message: error)
                    } else {
                        leaveEntriesSection
                    }
                }
                .padding(.horizontal) // 只保留水平padding
                .padding(.bottom) // 只保留底部padding
            }
            .contentMargins(.top, 0) // 移除顶部内容边距
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.orange)
                        Text(localizationManager.localized(.leaveTitle))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.loadLeaveInfo()
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
            if viewModel.leaveEntries.isEmpty && !viewModel.isLoading {
                viewModel.loadLeaveInfo()
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.orange)

            Text(localizationManager.localized(.loadingLeaveInfo))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
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
                viewModel.loadLeaveInfo()
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

    // MARK: - Summary Header
    private var summaryHeaderView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text(localizationManager.localized(.leaveWeeklyOverview))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(spacing: 16) {
                StatBadge(
                    title: localizationManager.localized(.leaveToday),
                    count: getTodayLeaveCount(),
                    color: .orange
                )

                StatBadge(
                    title: localizationManager.localized(.leaveTomorrow),
                    count: getTomorrowLeaveCount(),
                    color: .blue
                )

                StatBadge(
                    title: localizationManager.localized(.leaveWeekly),
                    count: getWeeklyLeaveCount(),
                    color: .purple
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
    private func getTodayLeaveCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return viewModel.leaveEntries.filter { entry in
            guard let start = entry.startDate, let end = entry.endDate else { return false }
            return (start...end).contains(today)
        }.count
    }

    private func getTomorrowLeaveCount() -> Int {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return 0 }
        let tomorrowStart = Calendar.current.startOfDay(for: tomorrow)
        return viewModel.leaveEntries.filter { entry in
            guard let start = entry.startDate, let end = entry.endDate else { return false }
            return (start...end).contains(tomorrowStart)
        }.count
    }

    private func getWeeklyLeaveCount() -> Int {
        let today = Date()
        let calendar = Calendar.current

        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else { return 0 }

        return viewModel.leaveEntries.filter { entry in
            guard let start = entry.startDate, let end = entry.endDate else { return false }
            return weekInterval.intersects(DateInterval(start: start, end: end))
        }.count
    }

    private func refreshData() async {
        isRefreshing = true
        viewModel.loadLeaveInfo()
        isRefreshing = false
    }

    private var leaveEntriesSection: some View {
        VStack(spacing: 16) {
            // Summary header
            summaryHeaderView

            // Daily leave overview
            ForEach(0..<7) { offset in
                let day = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                let entries = viewModel.leaveEntries.filter { entry in
                    guard let start = entry.startDate, let end = entry.endDate else { return false }
                    let dayStart = Calendar.current.startOfDay(for: day)
                    return (start...end).contains(dayStart)
                }

                DayLeaveCard(
                    date: day,
                    entries: entries,
                    isToday: Calendar.current.isDateInToday(day)
                )
            }
        }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Day Leave Card
struct DayLeaveCard: View {
    let date: Date
    let entries: [BambooLeaveInfo]
    let isToday: Bool
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayName)
                        .font(.headline)
                        .fontWeight(isToday ? .bold : .medium)
                        .foregroundColor(isToday ? .blue : .primary)

                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if isToday {
                    Text(localizationManager.localized(.leaveToday))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()

                LeaveCountBadge(count: entries.count)
            }

            if entries.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(localizationManager.localized(.leaveAllPresent))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.05))
                .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(entries, id: \.id) { entry in
                        ModernLeaveEntryRow(entry: entry)
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isToday ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }

    private var dayName: String {
        let formatter = DateFormatter()
        if localizationManager.currentLanguage == "zh-Hans" {
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: date)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        if localizationManager.currentLanguage == "zh-Hans" {
            formatter.dateFormat = "M月d日"
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.dateFormat = "MMM d"
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: date)
    }
}

// MARK: - Leave Count Badge
struct LeaveCountBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(minWidth: 20, minHeight: 20)
                .background(Color.orange)
                .cornerRadius(10)
        } else {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Modern Leave Entry Row
struct ModernLeaveEntryRow: View {
    let entry: BambooLeaveInfo

    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            AvatarView(name: entry.name, photoUrl: entry.photoUrl, size: 36)
                .overlay(
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    LeaveTypeIcon(type: entry.type)

                    Text(entry.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let duration = entry.leaveDuration {
                    Text("\(duration)d")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }

                if let startDate = entry.startDate {
                    Text(startDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Leave Type Icon
struct LeaveTypeIcon: View {
    let type: String

    var body: some View {
        Group {
            switch type.lowercased() {
            case "vacation", "年假":
                Image(systemName: "beach.umbrella.fill")
                    .foregroundColor(.blue)
            case "sick", "病假":
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            case "personal", "事假":
                Image(systemName: "person.fill")
                    .foregroundColor(.purple)
            default:
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.orange)
            }
        }
        .font(.system(size: 12))
        .frame(width: 16, height: 16)
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = LeaveViewModel(bambooHRService: service)
    return LeaveView(viewModel: viewModel)
}
