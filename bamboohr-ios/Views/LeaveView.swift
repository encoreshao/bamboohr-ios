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
    @State private var showingRequestTimeOff = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(message: error)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                leaveEntriesSection(proxy: proxy)
                            }
                            .padding(.horizontal) // 只保留水平padding
                            .padding(.bottom) // 只保留底部padding
                        }
                        .contentMargins(.top, -15) // 移除顶部内容边距
                        .refreshable {
                            await refreshData()
                        }
                    }
                }
            }
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
                            .foregroundColor(.orange)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .onAppear {
            if viewModel.leaveEntries.isEmpty && !viewModel.isLoading {
                viewModel.loadLeaveInfo()
            }
        }
        .sheet(isPresented: $showingRequestTimeOff) {
            RequestTimeOffView(viewModel: viewModel)
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
                        .tint(.orange)

                    // Animated dots
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(.orange)
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
                    Text(localizationManager.localized(.leaveLoadingInfo))
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
                        viewModel.loadLeaveInfo()
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
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: true)
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Summary Header
    private func summaryHeaderView(proxy: ScrollViewProxy) -> some View {
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
                ) {
                    // 点击今天时跳转到今天的section
                    withAnimation(.easeInOut(duration: 0.6)) {
                        proxy.scrollTo(Date(), anchor: .top)
                    }
                }

                StatBadge(
                    title: localizationManager.localized(.leaveTomorrow),
                    count: getTomorrowLeaveCount(),
                    color: .blue
                ) {
                    // 点击明天时跳转到明天的section
                    if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            proxy.scrollTo(tomorrow, anchor: .top)
                        }
                    }
                }

                StatBadge(
                    title: localizationManager.localized(.leaveWeekly),
                    count: getWeeklyLeaveCount(),
                    color: .purple
                ) {
                    // 点击本周时跳转到第一个section（今天）
                    withAnimation(.easeInOut(duration: 0.6)) {
                        proxy.scrollTo(Date(), anchor: .top)
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

    private func leaveEntriesSection(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 16) {
            // Summary header
            summaryHeaderView(proxy: proxy)

            // Request Time Off Button
            requestTimeOffButton

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
                .id(day) // Add ID for scrolling
            }
        }
    }

    // MARK: - Request Time Off Button
    private var requestTimeOffButton: some View {
        Button {
            showingRequestTimeOff = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.2), .orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(localizationManager.localized(.leaveRequestTimeOff))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(localizationManager.localized(.leaveRequestTimeOffSubtitle))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.orange.opacity(0.3), .orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: showingRequestTimeOff)
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let title: String
    let count: Int
    let color: Color
    let action: () -> Void

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
        .onTapGesture {
            action()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
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
