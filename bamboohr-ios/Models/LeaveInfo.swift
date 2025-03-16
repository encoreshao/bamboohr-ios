//
//  LeaveInfo.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import SwiftData

@Model
final class LeaveInfo {
    var id: String
    var employeeId: String
    var employeeName: String
    var leaveType: String
    var startDate: Date
    var endDate: Date

    init(id: String, employeeId: String, employeeName: String, leaveType: String, startDate: Date, endDate: Date) {
        self.id = id
        self.employeeId = employeeId
        self.employeeName = employeeName
        self.leaveType = leaveType
        self.startDate = startDate
        self.endDate = endDate
    }

    var isOnLeaveToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)

        return (start...end).contains(today)
    }

    var leaveDuration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1
    }
}

// MARK: - Codable Extension
extension LeaveInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case employeeId
        case name
        case type
        case start
        case end
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Convert numeric IDs to strings
        let idInt = try container.decode(Int.self, forKey: .id)
        let employeeIdInt = try container.decode(Int.self, forKey: .employeeId)
        let name = try container.decode(String.self, forKey: .name)
        let type = try container.decode(String.self, forKey: .type)

        // Parse date strings in YYYY-MM-DD format
        let startString = try container.decode(String.self, forKey: .start)
        let endString = try container.decode(String.self, forKey: .end)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let start = dateFormatter.date(from: startString),
              let end = dateFormatter.date(from: endString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .start,
                in: container,
                debugDescription: "Date string does not match format expected by formatter."
            )
        }

        self.init(
            id: String(idInt),
            employeeId: String(employeeIdInt),
            employeeName: name,
            leaveType: type,
            startDate: start,
            endDate: end
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Convert string IDs to integers for API
        if let idInt = Int(id) {
            try container.encode(idInt, forKey: .id)
        }

        if let employeeIdInt = Int(employeeId) {
            try container.encode(employeeIdInt, forKey: .employeeId)
        }

        try container.encode(employeeName, forKey: .name)
        try container.encode(leaveType, forKey: .type)

        // Convert dates to strings
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startString = dateFormatter.string(from: startDate)
        let endString = dateFormatter.string(from: endDate)

        try container.encode(startString, forKey: .start)
        try container.encode(endString, forKey: .end)
    }
}
