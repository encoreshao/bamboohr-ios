//
//  PeopleView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct PeopleView: View {
    @ObservedObject var viewModel: PeopleViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.selectedEmployee != nil {
                    // Employee Details View
                    employeeDetailsView
                } else {
                    // Employee List View
                    employeeListView
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.green)
                        Text(viewModel.selectedEmployee != nil ?
                             localizationManager.localized(.peopleEmployeeDetails) :
                             localizationManager.localized(.peopleTitle))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }

                if viewModel.selectedEmployee != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.clearSelection()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text(localizationManager.localized(.peopleBackToList))
                            }
                            .foregroundColor(.blue)
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.loadEmployees()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
        }
        .onAppear {
            if viewModel.employees.isEmpty && !viewModel.isLoading {
                viewModel.loadEmployees()
            }
        }
    }

    // MARK: - Employee List View
    private var employeeListView: some View {
        VStack(spacing: 0) {
            // Search Bar - Always at top
            searchBar

            // Content below search bar
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(message: error)
            } else if viewModel.filteredEmployees.isEmpty {
                noResultsView
            } else {
                employeesList
            }
        }
        .refreshable {
            await refreshData()
        }
    }

    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField(localizationManager.localized(.peopleSearchPlaceholder), text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            // 数据来源指示器
            Group {
                if viewModel.isUsingMockData && !viewModel.isLoading {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("Demo Data")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.trailing, 16)
                        }
                    }
                }
            }
        )
    }

    private var employeesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredEmployees, id: \.id) { employee in
                    EmployeeRowView(employee: employee) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.loadEmployeeDetails(for: employee)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text(localizationManager.localized(.peopleNoResults))
                .font(.headline)
                .foregroundColor(.secondary)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Text(localizationManager.localized(.cancel))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Employee Details View
    private var employeeDetailsView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let employee = viewModel.selectedEmployee {
                    // Profile Header - Full width
                    profileHeader(employee: employee)
                        .padding(.bottom, 20)

                    // Content sections with horizontal padding
                    VStack(spacing: 20) {
                        // Work Information
                        workInfoSection(employee: employee)

                        // Contact Information
                        contactInfoSection(employee: employee)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }

    private func profileHeader(employee: User) -> some View {
        VStack(spacing: 24) {
            // Avatar with enhanced styling
            ZStack {
                // Background gradient circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.2), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                AvatarView(name: employee.fullName, photoUrl: employee.photoUrl, size: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white, .green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                    )
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            // Enhanced name and info section
            VStack(spacing: 12) {
                // Name with better typography
                VStack(spacing: 6) {
                    Text(employee.fullName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)

                    // Nickname display if available
                    if let nickname = employee.nickname, !nickname.isEmpty, nickname != employee.firstName {
                        Text("(\(nickname))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }

                    // Job title with smaller, different styling
                    Text(employee.jobTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.green.opacity(0.03),
                    Color.blue.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func workInfoSection(employee: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text(localizationManager.localized(.peopleWorkInfo))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 8) {
                InfoDetailRow(
                    icon: "person.text.rectangle",
                    title: localizationManager.localized(.peopleEmployeeID),
                    value: employee.id
                )

                InfoDetailRow(
                    icon: "briefcase",
                    title: localizationManager.localized(.homeWorkStatus),
                    value: employee.jobTitle
                )

                InfoDetailRow(
                    icon: "building.2",
                    title: localizationManager.localized(.peopleDepartment),
                    value: employee.department
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

    private func contactInfoSection(employee: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(localizationManager.localized(.peopleContactInfo))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 8) {
                if let location = employee.location {
                    InfoDetailRow(
                        icon: "location",
                        title: localizationManager.localized(.peopleLocation),
                        value: location
                    )
                }

                if let email = employee.email {
                    InfoDetailRow(
                        icon: "envelope",
                        title: localizationManager.localized(.peopleEmail),
                        value: email
                    )
                } else {
                    InfoDetailRow(
                        icon: "envelope",
                        title: localizationManager.localized(.peopleEmail),
                        value: localizationManager.localized(.peopleNotAvailable)
                    )
                }

                if let phone = employee.phone {
                    InfoDetailRow(
                        icon: "phone",
                        title: localizationManager.localized(.peoplePhone),
                        value: phone
                    )
                } else {
                    InfoDetailRow(
                        icon: "phone",
                        title: localizationManager.localized(.peoplePhone),
                        value: localizationManager.localized(.peopleNotAvailable)
                    )
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

    // MARK: - Loading and Error Views
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.green)

            Text(localizationManager.localized(.peopleLoadingEmployees))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

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
                viewModel.loadEmployees()
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

    private func refreshData() async {
        isRefreshing = true
        viewModel.loadEmployees()
        isRefreshing = false
    }
}

// MARK: - Employee Row View
struct EmployeeRowView: View {
    let employee: User
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Avatar
                AvatarView(name: employee.fullName, photoUrl: employee.photoUrl, size: 50)

                // Employee Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(employee.fullName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text(employee.jobTitle)
                        .font(.subheadline)
                        .foregroundColor(.green)

                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(employee.department)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Info Detail Row
struct InfoDetailRow: View {
    let icon: String
    let title: String
    let value: String

    private var isActionable: Bool {
        let notAvailableText = LocalizationManager.shared.localized(.peopleNotAvailable)
        return value != notAvailableText && !value.isEmpty
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 18, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)

                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isActionable ? .primary : .secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Add action button for email and phone
            if icon == "envelope" && isActionable {
                Button {
                    if let url = URL(string: "mailto:\(value)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            } else if icon == "phone" && isActionable {
                Button {
                    let cleanedPhone = value.replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: ")", with: "")
                        .replacingOccurrences(of: "-", with: "")
                    if let url = URL(string: "tel:\(cleanedPhone)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "phone.circle")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = PeopleViewModel(bambooHRService: service)
    return PeopleView(viewModel: viewModel)
}