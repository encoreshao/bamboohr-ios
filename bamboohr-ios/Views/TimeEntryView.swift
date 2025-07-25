//
//  TimeEntryView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct TimeEntryView: View {
    @ObservedObject var viewModel: TimeEntryViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingDatePicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current date records section
                    todayRecordsSection

                    // Time entry form
                    timeEntryForm
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.circle.fill")
                            .foregroundColor(.blue)
                        Text(localizationManager.localized(.timeTitle))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring()) {
                            viewModel.selectedDate = Date()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.circle.fill")
                                .foregroundColor(.blue)
                            Text(localizationManager.localized(.timeToday))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.loadProjects()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isLoading || viewModel.isSubmitting)
                }
            }
        }
        .onAppear {
            if viewModel.projects.isEmpty && !viewModel.isLoading {
                viewModel.loadProjects()
            }
            viewModel.loadTimeEntries()
        }
    }

    // MARK: - Records Section
    private var todayRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(recordsSectionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if viewModel.isLoadingEntries {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(localizationManager.localized(.timeTotalHours))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.formattedTotalHours) \(localizationManager.localized(.homeHours))")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }

            if viewModel.timeEntries.isEmpty && !viewModel.isLoadingEntries {
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(localizationManager.localized(.timeNoRecords))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.timeEntries, id: \.id) { entry in
                        TimeEntryRowView(entry: entry)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    // Helper to generate dynamic records section title
    private var recordsSectionTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(viewModel.selectedDate) {
            return localizationManager.localized(.timeTodayRecords)
        } else {
            return localizationManager.localized(.timeRecordsFor)
        }
    }

    // MARK: - Time Entry Form
    private var timeEntryForm: some View {
        VStack(spacing: 20) {
            // Date Selection
            dateSelectionSection

            // Hours Input
            hoursInputSection

            // Project and Task Selection
            projectSelectionSection

            // Notes Input
            notesSection

            // Submit Button
            submitButton
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(localizationManager.localized(.timeSelectDate), systemImage: "calendar")
                .font(.headline)
                .foregroundColor(.primary)

            Button(action: {
                withAnimation(.spring()) {
                    showingDatePicker.toggle()
                }
            }) {
                HStack {
                    Text(formattedDate)
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: showingDatePicker ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            if showingDatePicker {
                DatePicker(
                    localizationManager.localized(.timeSelectDate),
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .labelsHidden()
                .transition(.opacity.combined(with: .scale))
            }
        }
    }

    private var hoursInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localizationManager.localized(.timeWorkDuration), systemImage: "clock")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                HStack {
                    Text(localizationManager.localized(.timeDuration))
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()

                    HStack(spacing: 8) {
                        Button("-") {
                            if viewModel.hours > 0.5 {
                                viewModel.hours -= 0.5
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.hours <= 0.5)

                        Text("\(viewModel.hours, specifier: "%.1f") \(localizationManager.localized(.homeHours))")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(minWidth: 100)

                        Button("+") {
                            if viewModel.hours < 24.0 {
                                viewModel.hours += 0.5
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.hours >= 24.0)
                    }
                }

                Slider(
                    value: $viewModel.hours,
                    in: 0.5...24.0,
                    step: 0.5
                ) {
                    Text(localizationManager.localized(.timeWorkDuration))
                } minimumValueLabel: {
                    Text("0.5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("24")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .tint(.blue)
            }
        }
    }

    private var projectSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(localizationManager.localized(.timeProject), systemImage: "folder")
                .font(.headline)
                .foregroundColor(.primary)

            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(localizationManager.localized(.loading))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if viewModel.projects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    Text(localizationManager.localized(.timeNoProjects))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    // Project Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("", selection: $viewModel.selectedProject) {
                            Text(localizationManager.localized(.timeSelectProject)).tag(nil as Project?)
                            ForEach(viewModel.projects, id: \.id) { project in
                                HStack {
                                    Text(project.name)
                                    Spacer()
                                    if !project.tasks.isEmpty {
                                        Text("\(project.tasks.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                                .tag(project as Project?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity)
                    }

                    // Task Selection (if available)
                    if let project = viewModel.selectedProject, !project.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("", selection: $viewModel.selectedTask) {
                                Text(localizationManager.localized(.timeSelectTask)).tag(nil as Task?)
                                ForEach(project.tasks, id: \.id) { task in
                                    Text(task.name).tag(task as Task?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                        }
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedProject?.id)
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(localizationManager.localized(.timeNotes), systemImage: "text.alignleft")
                .font(.headline)
                .foregroundColor(.primary)

            TextEditor(text: $viewModel.note)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }

    private var submitButton: some View {
        Button(action: {
            viewModel.submitTimeEntry()
        }) {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(viewModel.isSubmitting ? localizationManager.localized(.timeSubmitting) : localizationManager.localized(.timeSubmit))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.isSubmitting ? Color.gray : Color.blue)
            )
        }
        .disabled(viewModel.isSubmitting)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSubmitting)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        if localizationManager.currentLanguage == "zh-Hans" {
            formatter.dateFormat = "M月d日 EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.dateFormat = "MMM d, EEEE"
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: viewModel.selectedDate)
    }

    private func getLocalizedText(_ chinese: String, _ english: String) -> String {
        return localizationManager.currentLanguage == "zh-Hans" ? chinese : english
    }
}

// MARK: - Time Entry Row View
struct TimeEntryRowView: View {
    let entry: TimeEntry
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if let projectName = entry.projectName {
                    Text(projectName)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                if let taskName = entry.taskName {
                    Text(taskName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(entry.hours, specifier: "%.1f")h")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text(localizationManager.localized(.timeSubmitted))
                    .font(.caption2)
                    .foregroundColor(.green)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = TimeEntryViewModel(bambooHRService: service)
    return TimeEntryView(viewModel: viewModel)
}
