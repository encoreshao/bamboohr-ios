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

    init(id: String, firstName: String, lastName: String, jobTitle: String, department: String, photoUrl: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.jobTitle = jobTitle
        self.department = department
        self.photoUrl = photoUrl
    }

    var fullName: String {
        return "\(firstName) \(lastName)"
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
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let firstName = try container.decode(String.self, forKey: .firstName)
        let lastName = try container.decode(String.self, forKey: .lastName)
        let jobTitle = try container.decode(String.self, forKey: .jobTitle)
        let department = try container.decode(String.self, forKey: .department)
        let photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)

        self.init(
            id: id,
            firstName: firstName,
            lastName: lastName,
            jobTitle: jobTitle,
            department: department,
            photoUrl: photoUrl
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
    }
}
