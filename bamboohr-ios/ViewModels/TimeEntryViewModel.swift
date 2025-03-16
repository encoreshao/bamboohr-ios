//
//  TimeEntryViewModel.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine
import SwiftUI

class TimeEntryViewModel: ObservableObject {
    @Published var timeEntries: [TimeEntry] = []
    @Published var projects: [Project] = []
    @Published var selectedDate = Date()
    @Published var hours: Double = 8.0
    @Published var selectedProject: Project?
    @Published var selectedTask: Task?
    @Published var note: String = ""
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?
    @Published var successMessage: String?

    private var bambooHRService: BambooHRService
    private var cancellables = Set<AnyCancellable>()

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService

        // Reset selected task when selected project changes
        $selectedProject
            .sink { [weak self] project in
                self?.selectedTask = nil
            }
            .store(in: &cancellables)
    }

    func loadProjects() {
        isLoading = true
        error = nil

        bambooHRService.fetchProjects()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false

                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] projects in
                    self?.projects = projects.filter { $0.isActive }
                    if let firstProject = projects.first {
                        self?.selectedProject = firstProject
                    }
                }
            )
            .store(in: &cancellables)
    }

    func submitTimeEntry() {
        guard let selectedProject = selectedProject else {
            error = "Please select a project"
            return
        }

        isSubmitting = true
        error = nil
        successMessage = nil
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Create a new time entry
        let timeEntry = TimeEntry(
            employeeId: KeychainManager.shared.loadAccountSettings()?.employeeId ?? "",
            date: selectedDate,
            hours: hours,
            projectId: selectedProject.id,
            projectName: selectedProject.name,
            taskId: selectedTask?.id,
            taskName: selectedTask?.name,
            note: note.isEmpty ? nil : note
        )

        bambooHRService.submitTimeEntry(timeEntry)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSubmitting = false

                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.successMessage = "Time entry submitted successfully"
                        self?.resetForm()
                    } else {
                        self?.error = "Failed to submit time entry"
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func resetForm() {
        hours = 8.0
        note = ""
        selectedDate = Date()
        selectedTask = nil
    }
}
