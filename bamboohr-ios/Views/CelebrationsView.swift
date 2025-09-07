//
//  CelebrationsView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct CelebrationsSection: View {
    @ObservedObject var viewModel: CelebrationViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with expand/collapse button
            headerView

            // Content
            if isExpanded {
                contentView
                    .transition(.opacity.combined(with: .scale))
            } else {
                // Compact view showing next 3 celebrations
                compactView
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
        .onAppear {
            if viewModel.celebrations.isEmpty {
                viewModel.loadCelebrations()
            }
        }
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "party.popper.fill")
                .foregroundColor(.blue)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(getLocalizedText("庆祝活动", "Celebrations"))
                        .font(.headline)
                        .fontWeight(.semibold)

                    if viewModel.isUsingSampleData {
                        Text(getLocalizedText("示例", "Sample"))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(3)
                    }
                }

                Text(getLocalizedText("即将到来的生日和周年纪念", "Upcoming birthdays & anniversaries"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !viewModel.celebrations.isEmpty {
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.celebrations.isEmpty {
            emptyStateView
        } else {
            celebrationsListView
        }
    }

    private var compactView: some View {
        VStack(spacing: 8) {
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(getLocalizedText("加载中...", "Loading..."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if viewModel.celebrations.isEmpty {
                Text(getLocalizedText("未来6个月没有庆祝活动", "No celebrations in the next 6 months"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                let nextThree = Array(viewModel.upcomingCelebrations.prefix(3))
                ForEach(nextThree) { celebration in
                    CelebrationCompactRow(celebration: celebration, viewModel: viewModel)
                }

                if viewModel.upcomingCelebrations.count > 3 {
                    HStack {
                        Spacer()
                        Text(getLocalizedText("还有 \(viewModel.upcomingCelebrations.count - 3) 个庆祝活动...", "and \(viewModel.upcomingCelebrations.count - 3) more..."))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(getLocalizedText("加载庆祝活动...", "Loading celebrations..."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(minHeight: 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.gray)

            Text(getLocalizedText("没有即将到来的庆祝活动", "No upcoming celebrations"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(getLocalizedText("未来6个月内没有生日或工作周年纪念", "No birthdays or work anniversaries in the next 6 months"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }

    private var celebrationsListView: some View {
        LazyVStack(spacing: 6) {
            ForEach(viewModel.groupedCelebrations, id: \.0) { (groupTitle, celebrations) in
                VStack(alignment: .leading, spacing: 8) {
                    // Group header
                    HStack {
                        Text(getLocalizedText(groupTitle == "Today" ? "今天" : groupTitle == "This Week" ? "本周" : "即将到来", groupTitle))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(celebrations.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }

                    // Group celebrations
                    ForEach(celebrations) { celebration in
                        CelebrationRow(celebration: celebration, viewModel: viewModel)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func getLocalizedText(_ chinese: String, _ english: String) -> String {
        return localizationManager.currentLanguage == "zh-Hans" ? chinese : english
    }
}

// MARK: - Celebration Row Views
struct CelebrationRow: View {
    let celebration: Celebration
    @ObservedObject var viewModel: CelebrationViewModel
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture or Icon
            if let profileImageUrl = celebration.profileImageUrl {
                AvatarView(name: celebration.employeeName, photoUrl: profileImageUrl, size: 44)
            } else {
                ZStack {
                    Circle()
                        .fill(viewModel.celebrationColor(for: celebration.type).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: celebration.type.iconName)
                        .foregroundColor(viewModel.celebrationColor(for: celebration.type))
                        .font(.system(size: 18, weight: .semibold))
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(celebration.employeeName)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(getLocalizedCelebrationDescription())
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let department = celebration.department {
                    Text(department)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(viewModel.formattedDateText(for: celebration))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.celebrationColor(for: celebration.type))

                Text(viewModel.timeUntilText(for: celebration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(8)
    }

    private func getLocalizedCelebrationDescription() -> String {
        switch celebration.type {
        case .birthday:
            return getLocalizedText("生日", "Birthday")
        case .workAnniversary:
            if let years = celebration.yearsCount {
                let yearText = getLocalizedText("年", years == 1 ? "Year" : "Years")
                let anniversaryText = getLocalizedText("工作周年", "Work Anniversary")
                return "\(years) \(yearText) \(anniversaryText)"
            } else {
                return getLocalizedText("工作周年", "Work Anniversary")
            }
        }
    }

    private func getLocalizedText(_ chinese: String, _ english: String) -> String {
        return localizationManager.currentLanguage == "zh-Hans" ? chinese : english
    }
}

struct CelebrationCompactRow: View {
    let celebration: Celebration
    @ObservedObject var viewModel: CelebrationViewModel

    var body: some View {
        HStack(spacing: 8) {
            // Show profile picture if available, otherwise show type icon
            if let profileImageUrl = celebration.profileImageUrl {
                AvatarView(name: celebration.employeeName, photoUrl: profileImageUrl, size: 20)
            } else {
                Image(systemName: celebration.type.iconName)
                    .foregroundColor(viewModel.celebrationColor(for: celebration.type))
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 20)
            }

            Text(celebration.employeeName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()

            Text(viewModel.formattedDateText(for: celebration))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6).opacity(0.2))
        .cornerRadius(6)
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = CelebrationViewModel(bambooHRService: service)

    return CelebrationsSection(viewModel: viewModel)
        .padding()
}
