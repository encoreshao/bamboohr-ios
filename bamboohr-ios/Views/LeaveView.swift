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
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 50)
                    } else if let error = viewModel.error {
                        ErrorView(message: error, retryAction: {
                            viewModel.loadLeaveInfo()
                        })
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(0..<5) { offset in
                            let day = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                            let entries = viewModel.leaveEntries.filter { entry in
                                guard let start = entry.startDate, let end = entry.endDate else { return false }
                                let dayStart = Calendar.current.startOfDay(for: day)
                                return (start...end).contains(dayStart)
                            }
                            SectionCard(
                                title: formattedDate(day),
                                entries: entries,
                                emptyText: "No one is on leave"
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Who's Out")
                            .font(.headline)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.loadLeaveInfo()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                isRefreshing = true
                viewModel.loadLeaveInfo()
                isRefreshing = false
            }
        }
        .onAppear {
            if viewModel.leaveEntries.isEmpty && !viewModel.isLoading {
                viewModel.loadLeaveInfo()
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct SectionCard: View {
    let title: String
    let entries: [BambooLeaveInfo]
    let emptyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding([.top, .horizontal])
                .padding(.bottom, 6)

            if entries.isEmpty {
                Text(emptyText)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \ .element.id) { index, entry in
                        LeaveEntryRow(entry: entry, isOdd: index % 2 == 1)
                        if entry.id != entries.last?.id {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .padding(.vertical, 4)
    }
}

struct LeaveEntryRow: View {
    let entry: BambooLeaveInfo
    let isOdd: Bool
    @EnvironmentObject var accountSettings: AccountSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                // Avatar
                if let urlString = entry.photoUrl, let url = URL(string: urlString), !accountSettings.apiKey.isEmpty {
                    AuthenticatedAsyncImage(url: url, apiKey: accountSettings.apiKey)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.gray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.headline)
                    Text(entry.type)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Off days badge (keep in main row)
                if let duration = entry.leaveDuration {
                    Text(String(format: "%d day%@", duration, duration > 1 ? "s" : ""))
                        .font(.caption2)
                        .padding(.horizontal,10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
            }
            // Date range on a separate line with extra padding
            if let startDate = entry.startDate, let endDate = entry.endDate {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .medium))
                    DateRangeView(startDate: startDate, endDate: endDate)
                        .font(.caption)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(isOdd ? Color(.systemGray6) : Color.clear)
    }
}

struct DateRangeView: View {
    let startDate: Date
    let endDate: Date

    var body: some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        return HStack(spacing: 4) {
            Text(dateFormatter.string(from: startDate))
                .font(.subheadline)

            if Calendar.current.startOfDay(for: startDate) != Calendar.current.startOfDay(for: endDate) {
                Text("to")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(dateFormatter.string(from: endDate))
                    .font(.subheadline)
            }
        }

    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = LeaveViewModel(bambooHRService: service)
    return LeaveView(viewModel: viewModel)
}
