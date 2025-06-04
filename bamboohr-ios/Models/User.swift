//
//  User.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import SwiftData

@Model
final class User {
    var id: String
    var firstName: String
    var lastName: String
    var jobTitle: String
    var department: String
    var photoUrl: String?
    var nickname: String?

    init(id: String, firstName: String, lastName: String, jobTitle: String, department: String, photoUrl: String? = nil, nickname: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.jobTitle = jobTitle
        self.department = department
        self.photoUrl = photoUrl
        self.nickname = nickname
    }

    var fullName: String {
        if let nickname = nickname, !nickname.isEmpty {
            return "\(nickname) \(lastName)"
        } else {
            return "\(firstName) \(lastName)"
        }
    }
}

// MARK: - Codable Extension
extension User: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case jobTitle
        case department
        case photoUrl
        case nickname
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let firstName = try container.decode(String.self, forKey: .firstName)
        let lastName = try container.decode(String.self, forKey: .lastName)
        let jobTitle = try container.decode(String.self, forKey: .jobTitle)
        let department = try container.decode(String.self, forKey: .department)
        let photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        let nickname = try container.decodeIfPresent(String.self, forKey: .nickname)

        self.init(
            id: id,
            firstName: firstName,
            lastName: lastName,
            jobTitle: jobTitle,
            department: department,
            photoUrl: photoUrl,
            nickname: nickname
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(jobTitle, forKey: .jobTitle)
        try container.encode(department, forKey: .department)
        try container.encodeIfPresent(photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(nickname, forKey: .nickname)
    }
}
