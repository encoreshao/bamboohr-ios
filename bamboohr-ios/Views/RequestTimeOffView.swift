//
//  RequestTimeOffView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct RequestTimeOffView: View {
    @ObservedObject var viewModel: LeaveViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var fromDate = Date()
    @State private var toDate = Date()
    @State private var selectedCategory: TimeOffCategory?
    @State private var amount: Double = 8.0
    @State private var note = ""
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView

                    // Form content
                    VStack(spacing: 20) {
                        dateSelectionSection
                        categorySelectionSection
                        amountSelectionSection
                        noteSection
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localized(.cancel)) {
                        dismiss()
                    }
                    .navigationGradientButtonStyle(color: .gray)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        submitRequest()
                    } label: {
                        HStack(spacing: 6) {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.subheadline)
                            }
                            Text(localizationManager.localized(.leaveRequestSubmit))
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .orange.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Request Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
                .onAppear {
            // Set default category from static categories
            if selectedCategory == nil && !viewModel.timeOffCategories.isEmpty {
                selectedCategory = viewModel.timeOffCategories.first
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
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
                        .frame(width: 60, height: 60)

                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localized(.leaveRequestTimeOff))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(localizationManager.localized(.leaveRequestTimeOffSubtitle))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Date Selection Section
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Date Range", icon: "calendar")

            VStack(spacing: 16) {
                dateFieldRow(title: localizationManager.localized(.leaveRequestFrom), date: $fromDate)
                dateFieldRow(title: localizationManager.localized(.leaveRequestTo), date: $toDate)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }

    private func dateFieldRow(title: String, date: Binding<Date>) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)

            DatePicker("", selection: date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
        }
    }

    // MARK: - Category Selection Section
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(localizationManager.localized(.leaveRequestCategory), icon: "tag.fill")

                        VStack(spacing: 0) {
                    Menu {
                        ForEach(viewModel.timeOffCategories) { category in
                            Button(category.displayText) {
                                selectedCategory = category
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory?.displayText ?? localizationManager.localized(.leaveRequestSelectCategory))
                                .font(.body)
                                .foregroundColor(selectedCategory != nil ? .primary : .secondary)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
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
    }

    // MARK: - Amount Selection Section
    private var amountSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(localizationManager.localized(.leaveRequestAmount), icon: "clock.fill")

            VStack(spacing: 16) {
                HStack {
                    TextField("8.0", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .font(.body)

                    Text("hours")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Note Section
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(localizationManager.localized(.leaveRequestNote), icon: "note.text")

            VStack(spacing: 0) {
                TextEditor(text: $note)
                    .font(.body)
                    .frame(minHeight: 100)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.orange)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()
        }
    }

    // MARK: - Submit Request
    private func submitRequest() {
        guard !isSubmitting else { return }

        // Validate dates
        guard fromDate <= toDate else {
            alertMessage = "End date must be after start date"
            showingAlert = true
            return
        }

                // Validate category selection
        guard let category = selectedCategory else {
            alertMessage = localizationManager.localized(.leaveRequestSelectCategoryError)
            showingAlert = true
            return
        }

        // Validate amount
        guard amount > 0 else {
            alertMessage = "Amount must be greater than 0"
            showingAlert = true
            return
        }

        isSubmitting = true

        // Create time off request
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let request = TimeOffRequest(
            employeeId: Int(KeychainManager.shared.loadAccountSettings()?.employeeId ?? "0") ?? 0,
            start: dateFormatter.string(from: fromDate),
            end: dateFormatter.string(from: toDate),
            timeOffTypeId: category.id,
            amount: amount,
            notes: note.isEmpty ? nil : note
        )

        // Submit the request
        viewModel.submitTimeOffRequest(request) { [self] success, message in
            DispatchQueue.main.async {
                isSubmitting = false
                alertMessage = message ?? (success ? "Request submitted successfully!" : "Failed to submit request")
                showingAlert = true

                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = LeaveViewModel(bambooHRService: service)
    return RequestTimeOffView(viewModel: viewModel)
}
