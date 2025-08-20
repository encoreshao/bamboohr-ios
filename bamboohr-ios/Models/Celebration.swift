//
//  Celebration.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation

// MARK: - Celebration Types
enum CelebrationType: String, CaseIterable, Codable {
    case birthday = "birthday"
    case workAnniversary = "work_anniversary"

    var displayName: String {
        switch self {
        case .birthday:
            return "Birthday"
        case .workAnniversary:
            return "Work Anniversary"
        }
    }

    var iconName: String {
        switch self {
        case .birthday:
            return "gift.fill"
        case .workAnniversary:
            return "star.circle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .birthday:
            return "pink"
        case .workAnniversary:
            return "orange"
        }
    }
}

// MARK: - Celebration Model
struct Celebration: Identifiable, Codable {
    let id: String
    let employeeId: String
    let employeeName: String
    let type: CelebrationType
    let date: Date
    let yearsCount: Int? // For work anniversaries, how many years
    let department: String?
    let profileImageUrl: String?

    init(id: String = UUID().uuidString,
         employeeId: String,
         employeeName: String,
         type: CelebrationType,
         date: Date,
         yearsCount: Int? = nil,
         department: String? = nil,
         profileImageUrl: String? = nil) {
        self.id = id
        self.employeeId = employeeId
        self.employeeName = employeeName
        self.type = type
        self.date = date
        self.yearsCount = yearsCount
        self.department = department
        self.profileImageUrl = profileImageUrl
    }

    // Helper computed properties
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var celebrationDescription: String {
        switch type {
        case .birthday:
            return "Birthday"
        case .workAnniversary:
            if let years = yearsCount {
                return "\(years) Year\(years == 1 ? "" : "s") Anniversary"
            } else {
                return "Work Anniversary"
            }
        }
    }
}

// MARK: - Sample Data Extension
extension Celebration {
    static var sampleData: [Celebration] {
        let calendar = Calendar.current
        let today = Date()

        return [
            Celebration(
                employeeId: "001",
                employeeName: "Alice Johnson",
                type: .birthday,
                date: calendar.date(byAdding: .day, value: 3, to: today) ?? today,
                department: "Engineering"
            ),
            Celebration(
                employeeId: "002",
                employeeName: "Bob Smith",
                type: .workAnniversary,
                date: calendar.date(byAdding: .day, value: 7, to: today) ?? today,
                yearsCount: 5,
                department: "Marketing"
            ),
            Celebration(
                employeeId: "003",
                employeeName: "Carol Davis",
                type: .birthday,
                date: calendar.date(byAdding: .day, value: 15, to: today) ?? today,
                department: "HR"
            ),
            Celebration(
                employeeId: "004",
                employeeName: "David Wilson",
                type: .workAnniversary,
                date: calendar.date(byAdding: .day, value: 22, to: today) ?? today,
                yearsCount: 2,
                department: "Sales"
            ),
            Celebration(
                employeeId: "005",
                employeeName: "Emma Brown",
                type: .birthday,
                date: calendar.date(byAdding: .day, value: 45, to: today) ?? today,
                department: "Design"
            )
        ]
    }
}
