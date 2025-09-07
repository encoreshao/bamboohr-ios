//
//  DataCacheManager.swift
//  bamboohr-ios
//
//  Created on 2025/9/7.
//

import Foundation
import Combine

/// Centralized cache manager for BambooHR API responses
class DataCacheManager: ObservableObject {
    static let shared = DataCacheManager()

    // MARK: - Cache Storage
    private var projectsCache: CacheItem<[Project]>?
    private var employeesCache: CacheItem<[User]>?
    private var whosOutCache: CacheItem<[BambooLeaveInfo]>?
    private var timeOffBalanceCache: CacheItem<Int>?
    private var currentUserCache: CacheItem<User>?

    // MARK: - Cache Configuration
    private let defaultCacheExpiry: TimeInterval = 300 // 5 minutes
    private let employeesCacheExpiry: TimeInterval = 1800 // 30 minutes (employees change less frequently)
    private let projectsCacheExpiry: TimeInterval = 3600 // 1 hour (projects change even less frequently)
    private let whosOutCacheExpiry: TimeInterval = 900 // 15 minutes

    // MARK: - Cache Statistics
    @Published var cacheHits: Int = 0
    @Published var cacheMisses: Int = 0
    @Published var totalRequests: Int = 0

    private init() {}

    // MARK: - Generic Cache Item
    private struct CacheItem<T> {
        let data: T
        let timestamp: Date
        let expiry: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > expiry
        }
    }

    // MARK: - Projects Cache
    func getCachedProjects() -> [Project]? {
        totalRequests += 1

        if let cache = projectsCache, !cache.isExpired {
            cacheHits += 1
            logCacheHit("projects", count: cache.data.count)
            return cache.data
        }

        cacheMisses += 1
        logCacheMiss("projects")
        return nil
    }

    func cacheProjects(_ projects: [Project]) {
        projectsCache = CacheItem(data: projects, timestamp: Date(), expiry: projectsCacheExpiry)
        logCacheStore("projects", count: projects.count, expiry: projectsCacheExpiry)
    }

    // MARK: - Employees Cache
    func getCachedEmployees() -> [User]? {
        totalRequests += 1

        if let cache = employeesCache, !cache.isExpired {
            cacheHits += 1
            logCacheHit("employees", count: cache.data.count)
            return cache.data
        }

        cacheMisses += 1
        logCacheMiss("employees")
        return nil
    }

    func cacheEmployees(_ employees: [User]) {
        employeesCache = CacheItem(data: employees, timestamp: Date(), expiry: employeesCacheExpiry)
        logCacheStore("employees", count: employees.count, expiry: employeesCacheExpiry)
    }

    // MARK: - Who's Out Cache
    func getCachedWhosOut(for dateRange: String) -> [BambooLeaveInfo]? {
        totalRequests += 1

        if let cache = whosOutCache, !cache.isExpired {
            cacheHits += 1
            logCacheHit("whos_out", count: cache.data.count)
            return cache.data
        }

        cacheMisses += 1
        logCacheMiss("whos_out")
        return nil
    }

    func cacheWhosOut(_ whosOut: [BambooLeaveInfo], for dateRange: String) {
        whosOutCache = CacheItem(data: whosOut, timestamp: Date(), expiry: whosOutCacheExpiry)
        logCacheStore("whos_out", count: whosOut.count, expiry: whosOutCacheExpiry)
    }

    // MARK: - Time Off Balance Cache
    func getCachedTimeOffBalance() -> Int? {
        totalRequests += 1

        if let cache = timeOffBalanceCache, !cache.isExpired {
            cacheHits += 1
            logCacheHit("time_off_balance", count: 1)
            return cache.data
        }

        cacheMisses += 1
        logCacheMiss("time_off_balance")
        return nil
    }

    func cacheTimeOffBalance(_ balance: Int) {
        timeOffBalanceCache = CacheItem(data: balance, timestamp: Date(), expiry: defaultCacheExpiry)
        logCacheStore("time_off_balance", count: 1, expiry: defaultCacheExpiry)
    }

    // MARK: - Current User Cache
    func getCachedCurrentUser() -> User? {
        totalRequests += 1

        if let cache = currentUserCache, !cache.isExpired {
            cacheHits += 1
            logCacheHit("current_user", count: 1)
            return cache.data
        }

        cacheMisses += 1
        logCacheMiss("current_user")
        return nil
    }

    func cacheCurrentUser(_ user: User) {
        currentUserCache = CacheItem(data: user, timestamp: Date(), expiry: employeesCacheExpiry)
        logCacheStore("current_user", count: 1, expiry: employeesCacheExpiry)
    }

    // MARK: - Cache Management
    func clearCache() {
        projectsCache = nil
        employeesCache = nil
        whosOutCache = nil
        timeOffBalanceCache = nil
        currentUserCache = nil

        // Reset statistics
        cacheHits = 0
        cacheMisses = 0
        totalRequests = 0

        print("🗑️ CACHE: All caches cleared")
    }

    func clearExpiredCaches() {
        var clearedCount = 0

        if let cache = projectsCache, cache.isExpired {
            projectsCache = nil
            clearedCount += 1
        }

        if let cache = employeesCache, cache.isExpired {
            employeesCache = nil
            clearedCount += 1
        }

        if let cache = whosOutCache, cache.isExpired {
            whosOutCache = nil
            clearedCount += 1
        }

        if let cache = timeOffBalanceCache, cache.isExpired {
            timeOffBalanceCache = nil
            clearedCount += 1
        }

        if let cache = currentUserCache, cache.isExpired {
            currentUserCache = nil
            clearedCount += 1
        }

        if clearedCount > 0 {
            print("🧹 CACHE: Cleared \(clearedCount) expired cache(s)")
        }
    }

    // MARK: - Cache Statistics
    var cacheHitRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(cacheHits) / Double(totalRequests) * 100.0
    }

    func printCacheStatistics() {
        print("📊 CACHE STATS: Requests: \(totalRequests), Hits: \(cacheHits), Misses: \(cacheMisses), Hit Rate: \(String(format: "%.1f", cacheHitRate))%")
    }

    // MARK: - Logging
    private func logCacheHit(_ type: String, count: Int) {
        print("✅ CACHE HIT: \(type) (\(count) items)")
    }

    private func logCacheMiss(_ type: String) {
        print("❌ CACHE MISS: \(type)")
    }

    private func logCacheStore(_ type: String, count: Int, expiry: TimeInterval) {
        print("💾 CACHE STORE: \(type) (\(count) items, expires in \(Int(expiry))s)")
    }
}

// MARK: - Cache-Aware BambooHR Service Extension
extension BambooHRService {

    // MARK: - Cached Projects
    func fetchProjectsCached() -> AnyPublisher<[Project], BambooHRError> {
        // Check cache first
        if let cachedProjects = DataCacheManager.shared.getCachedProjects() {
            return Just(cachedProjects)
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()
        }

        // Cache miss - fetch from API
        return fetchProjects()
            .handleEvents(receiveOutput: { projects in
                DataCacheManager.shared.cacheProjects(projects)
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Cached Employees
    func fetchEmployeeDirectoryCached() -> AnyPublisher<[User], BambooHRError> {
        // Check cache first
        if let cachedEmployees = DataCacheManager.shared.getCachedEmployees() {
            return Just(cachedEmployees)
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()
        }

        // Cache miss - fetch from API
        return fetchEmployeeDirectory()
            .handleEvents(receiveOutput: { employees in
                DataCacheManager.shared.cacheEmployees(employees)
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Cached Who's Out
    func fetchTimeOffEntriesCached(startDate: Date, endDate: Date) -> AnyPublisher<[BambooLeaveInfo], BambooHRError> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateRange = "\(dateFormatter.string(from: startDate))-\(dateFormatter.string(from: endDate))"

        // Check cache first
        if let cachedWhosOut = DataCacheManager.shared.getCachedWhosOut(for: dateRange) {
            return Just(cachedWhosOut)
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()
        }

        // Cache miss - fetch from API
        return fetchTimeOffEntries(startDate: startDate, endDate: endDate)
            .handleEvents(receiveOutput: { whosOut in
                DataCacheManager.shared.cacheWhosOut(whosOut, for: dateRange)
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Cached Time Off Balance
    func fetchTimeOffBalanceCached() -> AnyPublisher<Int, BambooHRError> {
        // Check cache first
        if let cachedBalance = DataCacheManager.shared.getCachedTimeOffBalance() {
            return Just(cachedBalance)
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()
        }

        // Cache miss - fetch from API
        return fetchTimeOffBalance()
            .handleEvents(receiveOutput: { balance in
                DataCacheManager.shared.cacheTimeOffBalance(balance)
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Cached Current User
    func fetchCurrentUserCached() -> AnyPublisher<User, BambooHRError> {
        // Check cache first
        if let cachedUser = DataCacheManager.shared.getCachedCurrentUser() {
            return Just(cachedUser)
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()
        }

        // Cache miss - fetch from API
        return fetchCurrentUser()
            .handleEvents(receiveOutput: { user in
                DataCacheManager.shared.cacheCurrentUser(user)
            })
            .eraseToAnyPublisher()
    }
}
