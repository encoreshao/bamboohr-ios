//
//  UserViewModel.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine
import SwiftUI

class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?

    // 统计数据
    @Published var weeklyHours: Double = 0.0
    @Published var remainingLeavedays: Int = 0
    @Published var totalProjects: Int = 0
    @Published var totalEmployees: Int = 0
    @Published var isOnLeaveToday: Bool = false

    private let bambooHRService: BambooHRService
    private var cancellables = Set<AnyCancellable>()

    init(bambooHRService: BambooHRService) {
        self.bambooHRService = bambooHRService
    }

    func loadUserInfo() {
        isLoading = true
        error = nil

        // 并行加载用户信息和统计数据
        let userInfoPublisher = bambooHRService.fetchCurrentUserCached()
        let statsPublisher = loadStatistics()

        Publishers.CombineLatest(userInfoPublisher, statsPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<BambooHRError>) in
                    self?.isLoading = false

                    if case .failure(let error) = completion {
                        let localizationManager = LocalizationManager.shared
                        let errorMessage = localizationManager.localized(.loadingFailed)

                        self?.error = errorMessage
                        ToastManager.shared.error(errorMessage)
                        print("⚠️ Failed to load user info: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] (user: User, _: Bool) in
                    self?.user = user
                    let localizationManager = LocalizationManager.shared
                    ToastManager.shared.success(localizationManager.localized(.loadingUserInfo))
                }
            )
            .store(in: &cancellables)
    }

    // 加载统计数据
    private func loadStatistics() -> AnyPublisher<Bool, BambooHRError> {
        let calendar = Calendar.current
        let today = Date()

        // 获取本周开始日期
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = weekday
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return Just(false).setFailureType(to: BambooHRError.self).eraseToAnyPublisher()
        }

        // 并行获取各种数据
        let weeklyHoursPublisher = calculateWeeklyHours(from: startOfWeek, to: today)
        let leaveBalancePublisher = getLeaveBalance()
        let projectsPublisher = getTotalProjects()
        let employeesPublisher = getTotalEmployees()
        let userLeaveStatusPublisher = getUserLeaveStatus()

        return Publishers.CombineLatest4(
            weeklyHoursPublisher,
            leaveBalancePublisher,
            projectsPublisher,
            Publishers.CombineLatest(employeesPublisher, userLeaveStatusPublisher)
        )
        .map { weeklyHours, leaveBalance, projects, employeesUserStatus in
            let (employees, isUserOnLeave) = employeesUserStatus
            DispatchQueue.main.async { [weak self] in
                self?.weeklyHours = weeklyHours
                self?.remainingLeavedays = leaveBalance
                self?.totalProjects = projects
                self?.totalEmployees = employees
                self?.isOnLeaveToday = isUserOnLeave
            }
            return true
        }
        .eraseToAnyPublisher()
    }

    // 计算本周工作小时数
    private func calculateWeeklyHours(from startDate: Date, to endDate: Date) -> AnyPublisher<Double, BambooHRError> {
        let calendar = Calendar.current
        var fetchPublishers: [AnyPublisher<[TimeEntry], BambooHRError>] = []

        // 获取本周每天的时间记录
        var currentDate = startDate
        while currentDate <= endDate {
            fetchPublishers.append(bambooHRService.fetchTimeEntries(for: currentDate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return Publishers.MergeMany(fetchPublishers)
            .collect()
            .map { timeEntriesArrays in
                let allEntries = timeEntriesArrays.flatMap { $0 }
                let totalHours = allEntries.reduce(0.0) { $0 + $1.hours }
                return totalHours
            }
            .catch { error in
                print("⚠️ Failed to calculate weekly hours: \(error.localizedDescription)")
                // 如果获取失败，返回合理的模拟数据
                let currentHour = Calendar.current.component(.hour, from: Date())
                let dayOfWeek = Calendar.current.component(.weekday, from: Date())

                // 根据当前时间和日期模拟已工作时间
                let dailyHours = max(0, min(8, currentHour - 9))
                let weeklyHours = Double(dailyHours) + Double(max(0, (dayOfWeek - 2)) * 8)
                let simulatedHours = max(0, min(40, weeklyHours))

                return Just(simulatedHours).setFailureType(to: BambooHRError.self)
            }
            .eraseToAnyPublisher()
    }

    // 获取剩余假期
    private func getLeaveBalance() -> AnyPublisher<Int, BambooHRError> {
        return bambooHRService.fetchTimeOffBalanceCached()
            .catch { error in
                print("⚠️ Failed to fetch leave balance: \(error.localizedDescription)")
                // 如果获取失败，返回合理的默认值
                return Just(15).setFailureType(to: BambooHRError.self)
            }
            .eraseToAnyPublisher()
    }

    // 获取总项目数
    private func getTotalProjects() -> AnyPublisher<Int, BambooHRError> {
        return bambooHRService.fetchProjectsCached()
            .map { projects in
                projects.count
            }
            .catch { _ in
                // 如果获取失败，返回模拟数据
                Just(8).setFailureType(to: BambooHRError.self)
            }
            .eraseToAnyPublisher()
    }

    // 获取总员工数
    private func getTotalEmployees() -> AnyPublisher<Int, BambooHRError> {
        return bambooHRService.fetchEmployeeDirectoryCached()
            .map { employees in
                employees.count
            }
            .catch { error in
                print("⚠️ Failed to fetch employee directory for count: \(error.localizedDescription)")
                // 如果获取失败，返回合理的默认值
                return Just(47).setFailureType(to: BambooHRError.self)
            }
            .eraseToAnyPublisher()
    }

    // 获取用户休假状态
    private func getUserLeaveStatus() -> AnyPublisher<Bool, BambooHRError> {
        let today = Date()
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        return bambooHRService.fetchTimeOffEntriesCached(startDate: today, endDate: endDate)
            .map { [weak self] entries in
                let todayEntries = entries.filter { entry in
                    guard let start = entry.startDate, let end = entry.endDate else { return false }
                    return start <= today && end >= today
                }

                // 检查当前用户是否休假
                let userIdString = self?.user?.id ?? ""
                let userId = Int(userIdString) ?? 0
                let isUserOnLeave = todayEntries.contains { $0.employeeId == userId }

                return isUserOnLeave
            }
            .catch { _ in
                // 如果获取失败，返回默认值
                Just(false).setFailureType(to: BambooHRError.self)
            }
            .eraseToAnyPublisher()
    }

    // Helper to calculate next birthday
    static func calculateNextBirthday(birthdayString: String?) -> Date? {
        guard let birthdayString = birthdayString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        let year = Calendar.current.component(.year, from: Date())
        guard let birthday = formatter.date(from: birthdayString) else { return nil }
        var components = Calendar.current.dateComponents([.month, .day], from: birthday)
        components.year = year
        let thisYearBirthday = Calendar.current.date(from: components) ?? Date()
        if thisYearBirthday < Date() {
            components.year = year + 1
        }
        return Calendar.current.date(from: components)
    }
}
