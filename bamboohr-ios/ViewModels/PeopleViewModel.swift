//
//  PeopleViewModel.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine
import SwiftUI

class PeopleViewModel: ObservableObject {
    @Published var employees: [User] = []
    @Published var filteredEmployees: [User] = []
    @Published var selectedEmployee: User?
    @Published var searchText = "" {
        didSet {
            filterEmployees()
        }
    }
    @Published var isLoading = false
    @Published var isLoadingDetails = false
    @Published var error: String?
    @Published var isUsingMockData = false

    private let bambooHRService: BambooHRService
    private var cancellables = Set<AnyCancellable>()

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService
    }

    func loadEmployees() {
        isLoading = true
        error = nil

        bambooHRService.fetchEmployeeDirectoryCached()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false

                    if case .failure(let error) = completion {
                        print("⚠️ Failed to load employees: \(error.localizedDescription)")

                        let localizationManager = LocalizationManager.shared
                        switch error {
                        case .authenticationError:
                            self?.error = localizationManager.localized(.authenticationError)
                        case .networkError(_):
                            self?.error = localizationManager.localized(.networkError)
                        default:
                            self?.error = localizationManager.localized(.loadingFailed)
                        }

                        // 如果API失败，显示模拟数据作为后备
                        print("📋 API failed, falling back to mock data")
                        self?.loadMockEmployees()
                    }
                },
                receiveValue: { [weak self] employees in
                    self?.employees = employees
                    self?.filteredEmployees = employees
                    self?.error = nil
                    self?.isUsingMockData = false

                    if employees.isEmpty {
                        print("📋 No employees returned from API, loading mock data")
                        self?.loadMockEmployees()
                    }
                }
            )
            .store(in: &cancellables)
    }

    func loadEmployeeDetails(for employee: User) {
        isLoadingDetails = true
        selectedEmployee = employee

        // 模拟加载详细信息的延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoadingDetails = false
        }
    }

    private func filterEmployees() {
        if searchText.isEmpty {
            filteredEmployees = employees
        } else {
            filteredEmployees = employees.filter { employee in
                employee.fullName.localizedCaseInsensitiveContains(searchText) ||
                employee.jobTitle.localizedCaseInsensitiveContains(searchText) ||
                employee.department.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private func loadMockEmployees() {
        print("📋 Loading mock employees as fallback")

        let mockEmployees = [
            User(id: "1", firstName: "John", lastName: "Smith", jobTitle: "Software Engineer", department: "Engineering", photoUrl: nil, nickname: nil, location: "San Francisco", email: "john.smith@company.com", phone: "+1 (415) 555-0123"),
            User(id: "2", firstName: "Alice", lastName: "Johnson", jobTitle: "Product Manager", department: "Product", photoUrl: nil, nickname: nil, location: "New York", email: "alice.johnson@company.com", phone: "+1 (212) 555-0456"),
            User(id: "3", firstName: "Bob", lastName: "Wilson", jobTitle: "UX Designer", department: "Design", photoUrl: nil, nickname: nil, location: "Los Angeles", email: "bob.wilson@company.com", phone: "+1 (310) 555-0789"),
            User(id: "4", firstName: "张", lastName: "三", jobTitle: "Backend Developer", department: "Engineering", photoUrl: nil, nickname: nil, location: "Shanghai", email: "zhang.san@company.com", phone: "+86 138 0013 8000"),
            User(id: "5", firstName: "李", lastName: "四", jobTitle: "DevOps Engineer", department: "Engineering", photoUrl: nil, nickname: nil, location: "Beijing", email: "li.si@company.com", phone: "+86 139 0139 0000"),
            User(id: "6", firstName: "Emily", lastName: "Davis", jobTitle: "Marketing Manager", department: "Marketing", photoUrl: nil, nickname: nil, location: "Chicago", email: "emily.davis@company.com", phone: "+1 (312) 555-1011"),
            User(id: "7", firstName: "Michael", lastName: "Brown", jobTitle: "Sales Representative", department: "Sales", photoUrl: nil, nickname: nil, location: "Austin", email: "michael.brown@company.com", phone: "+1 (512) 555-1213"),
            User(id: "8", firstName: "王", lastName: "小明", jobTitle: "QA Engineer", department: "Engineering", photoUrl: nil, nickname: nil, location: "Shenzhen", email: "wang.xiaoming@company.com", phone: "+86 135 0000 1357"),
            User(id: "9", firstName: "Sarah", lastName: "Miller", jobTitle: "HR Manager", department: "Human Resources", photoUrl: nil, nickname: nil, location: "Seattle", email: "sarah.miller@company.com", phone: "+1 (206) 555-1415"),
            User(id: "10", firstName: "David", lastName: "Garcia", jobTitle: "Data Scientist", department: "Data", photoUrl: nil, nickname: nil, location: "Boston", email: "david.garcia@company.com", phone: "+1 (617) 555-1617")
        ]

        self.employees = mockEmployees
        self.filteredEmployees = mockEmployees
        self.isLoading = false
        self.isUsingMockData = true

        print("📋 Loaded \(mockEmployees.count) mock employees")
    }

    func clearSelection() {
        selectedEmployee = nil
    }
}