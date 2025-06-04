//
//  LeaveView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

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
                    } else if viewModel.todayLeaveEntries.isEmpty && viewModel.tomorrowLeaveEntries.isEmpty {
                        ContentUnavailableView(
                            "No One is on Leave",
                            systemImage: "calendar.badge.checkmark",
                            description: Text("Everyone is available today and tomorrow.")
                        )
                        .padding()
                    } else {
                        // Today's leave section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Today (\(viewModel.todayLeaveEntries.count))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            if viewModel.todayLeaveEntries.isEmpty {
                                Text("No one is on leave today")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                            } else {
                                ForEach(viewModel.todayLeaveEntries, id: \.id) { entry in
                                    LeaveEntryRow(entry: entry)
                                }
                            }
                        }

                        // Tomorrow's leave section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tomorrow (\(viewModel.tomorrowLeaveEntries.count))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                                .padding(.top, 20)

                            if viewModel.tomorrowLeaveEntries.isEmpty {
                                Text("No one is on leave tomorrow")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                            } else {
                                ForEach(viewModel.tomorrowLeaveEntries, id: \.id) { entry in
                                    LeaveEntryRow(entry: entry)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        // Image("b-logo-green")
                        //     .resizable()
                        //     .scaledToFit()
                        //     .frame(height: 30)
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
}

struct LeaveEntryRow: View {
    let entry: BambooLeaveInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.headline)

                    Text(entry.type)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let startDate = entry.startDate, let endDate = entry.endDate {
                    DateRangeView(startDate: startDate, endDate: endDate)
                }
            }

            // Duration badge
            HStack {
                Spacer()
                if let duration = entry.leaveDuration {
                    Text(String(format: "%d day%@", duration, duration > 1 ? "s" : ""))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
        .padding(.horizontal)
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
