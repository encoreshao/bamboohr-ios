//
//  TimeEntryView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct TimeEntryView: View {
    @ObservedObject var viewModel: TimeEntryViewModel
    @State private var showingDatePicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date")) {
                    HStack {
                        Text(formattedDate)
                        Spacer()
                        Button(action: {
                            showingDatePicker.toggle()
                        }) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                    }

                    if showingDatePicker {
                        DatePicker(
                            "Select Date",
                            selection: $viewModel.selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                    }
                }

                Section(header: Text("Hours")) {
                    HStack {
                        Text("Hours Worked")
                        Spacer()
                        Stepper(
                            value: $viewModel.hours,
                            in: 0.5...24.0,
                            step: 0.5
                        ) {
                            Text("\(viewModel.hours, specifier: "%.1f")")
                                .font(.headline)
                        }
                    }

                    Slider(
                        value: $viewModel.hours,
                        in: 0.5...24.0,
                        step: 0.5
                    )
                }

                Section(header: Text("Project")) {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if viewModel.projects.isEmpty {
                        Text("No projects available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Project", selection: $viewModel.selectedProject) {
                            ForEach(viewModel.projects, id: \.id) { project in
                                Text(project.name).tag(project as Project?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                if let project = viewModel.selectedProject, !project.tasks.isEmpty {
                    Section(header: Text("Task")) {
                        Picker("Task", selection: $viewModel.selectedTask) {
                            Text("Select a task").tag(nil as Task?)
                            ForEach(project.tasks, id: \.id) { task in
                                Text(task.name).tag(task as Task?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                Section(header: Text("Note")) {
                    TextEditor(text: $viewModel.note)
                        .frame(minHeight: 100)
                }

                Section {
                    Button(action: {
                        viewModel.submitTimeEntry()
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .padding(.trailing, 10)
                            }
                            Text("Submit Time Entry")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isSubmitting)
                }

                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                if let successMessage = viewModel.successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        // Image("40")
                        //     .resizable()
                        //     .scaledToFit()
                        //     .frame(height: 30)
                        Text("Enter Time Worked")
                            .font(.headline)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.loadProjects()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading || viewModel.isSubmitting)
                }
            }
        }
        .onAppear {
            if viewModel.projects.isEmpty && !viewModel.isLoading {
                viewModel.loadProjects()
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: viewModel.selectedDate)
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = TimeEntryViewModel(bambooHRService: service)
    return TimeEntryView(viewModel: viewModel)
}
