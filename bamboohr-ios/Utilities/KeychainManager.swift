//
//  KeychainManager.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Security

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidItemFormat
    case unexpectedStatus(OSStatus)
}

class KeychainManager {

    static let shared = KeychainManager()

    private init() {}

    // MARK: - Save

    func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Item already exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]

            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)

            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func save(key: String, string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }

        try save(key: key, data: data)
    }

    // MARK: - Read

    func readData(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidItemFormat
        }

        return data
    }

    func readString(key: String) throws -> String {
        let data = try readData(key: key)

        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }

        return string
    }

    // MARK: - Delete

    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Account Settings

    func saveAccountSettings(_ settings: AccountSettings) throws {
        try save(key: "bamboohr_company_domain", string: settings.companyDomain)
        try save(key: "bamboohr_employee_id", string: settings.employeeId)
        try save(key: "bamboohr_api_key", string: settings.apiKey)
    }

    func loadAccountSettings() -> AccountSettings? {
        do {
            let companyDomain = try readString(key: "bamboohr_company_domain")
            let employeeId = try readString(key: "bamboohr_employee_id")
            let apiKey = try readString(key: "bamboohr_api_key")

            return AccountSettings(
                companyDomain: companyDomain,
                employeeId: employeeId,
                apiKey: apiKey,
                lastSyncDate: Date()
            )
        } catch {
            return nil
        }
    }

    func clearAccountSettings() throws {
        try delete(key: "bamboohr_company_domain")
        try delete(key: "bamboohr_employee_id")
        try delete(key: "bamboohr_api_key")
    }
}
