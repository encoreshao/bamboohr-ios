//
//  TimeOffRequest.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation

struct TimeOffRequest: Codable {
    let employeeId: Int
    let start: String
    let end: String
    let timeOffTypeId: String
    let amount: Double
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case employeeId = "employeeId"
        case start = "start"
        case end = "end"
        case timeOffTypeId = "timeOffTypeId"
        case amount = "amount"
        case notes = "note"
    }
}

struct TimeOffCategory: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let unit: String
    let type: String
    let icon: String
    let onPerHourWorkedLevel: Bool
    let total: Double
    let source: String
    let balance: Double?
    let usedYtd: Double

    // For UI display - convert string ID to Int for compatibility
    var intId: Int {
        return Int(id) ?? 0
    }

    // Helper to determine if category has unlimited balance
    var isUnlimited: Bool {
        return type == "unlimited"
    }

    // Helper for display text
    var displayText: String {
        return "\(name)"
        // if let balance = balance {
        //     return "\(name) (\(balance) \(unit) available)"
        // } else {
        //     return "\(name) (\(type))"
        // }
    }

    // Static hardcoded categories from provided JSON data
    static let defaultCategories: [TimeOffCategory] = [
        TimeOffCategory(
            id: "84",
            name: "Paid Leave",
            unit: "days",
            type: "regular",
            icon: "palm-trees",
            onPerHourWorkedLevel: false,
            total: 0,
            source: "internal",
            balance: 0,
            usedYtd: 0
        ),
        TimeOffCategory(
            id: "95",
            name: "Wellbeing Holiday",
            unit: "days",
            type: "regular",
            icon: "airplane",
            onPerHourWorkedLevel: false,
            total: 0,
            source: "internal",
            balance: 0,
            usedYtd: 0
        ),
        TimeOffCategory(
            id: "92",
            name: "OT compensation",
            unit: "hours",
            type: "unlimited",
            icon: "gavel",
            onPerHourWorkedLevel: false,
            total: 0,
            source: "internal",
            balance: nil,
            usedYtd: 0
        ),
        TimeOffCategory(
            id: "90",
            name: "Funeral Leave (SH)",
            unit: "days",
            type: "unlimited",
            icon: "selfie",
            onPerHourWorkedLevel: false,
            total: 0,
            source: "internal",
            balance: nil,
            usedYtd: 0
        ),
        TimeOffCategory(
            id: "86",
            name: "Marriage Leave",
            unit: "days",
            type: "unlimited",
            icon: "joining-hands",
            onPerHourWorkedLevel: false,
            total: 0,
            source: "internal",
            balance: nil,
            usedYtd: 0
        ),
        TimeOffCategory(
            id: "85",
            name: "Maternity Leave",
            unit: "days",
            type: "unlimited",
            icon: "baby-carriage",
            onPerHourWorkedLevel: false,
            total: 0,
            source: "internal",
            balance: nil,
            usedYtd: 0
        ),
        TimeOffCategory(
            id: "87",
            name: "Sick leave",
            unit: "hours",
            type: "unlimited",
            icon: "first-aid-kit",
            onPerHourWorkedLevel: false,
            total: 0,
            source: "internal",
            balance: nil,
            usedYtd: 0
        ),
        TimeOffCategory(
            id: "91",
            name: "Unpaid leave",
            unit: "days",
            type: "unlimited",
            icon: "happy-calendar",
            onPerHourWorkedLevel: false,
            total: 0,
            source: "internal",
            balance: nil,
            usedYtd: 0
        )
    ]
}



// MARK: - Time Off Request Response
struct TimeOffRequestResponse: Codable {
    let id: Int
    let employeeId: Int
    let name: String
    let start: String
    let end: String
    let created: String
    let type: String
    let amount: TimeOffAmount
    let actions: TimeOffActions
    let dates: [String: String]
    let notes: TimeOffNotes
}

struct TimeOffAmount: Codable {
    let unit: String
    let amount: String
}

struct TimeOffActions: Codable {
    let view: Bool
    let edit: Bool
    let cancel: Bool
    let approve: Bool
    let deny: Bool
    let bypass: Bool
}

struct TimeOffNotes: Codable {
    let employee: String?
    let manager: String?
}
