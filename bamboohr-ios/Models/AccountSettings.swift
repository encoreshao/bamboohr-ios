//
//  AccountSettings.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import SwiftData

@Model
final class AccountSettings {
    var companyDomain: String
    var employeeId: String
    var apiKey: String
    var lastSyncDate: Date?

    init(companyDomain: String, employeeId: String, apiKey: String, lastSyncDate: Date? = nil) {
        self.companyDomain = companyDomain
        self.employeeId = employeeId
        self.apiKey = apiKey
        self.lastSyncDate = lastSyncDate
    }

    var baseUrl: URL? {
        return URL(string: "https://api.bamboohr.com/api/gateway.php")
    }
}
