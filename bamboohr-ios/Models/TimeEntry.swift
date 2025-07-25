//
//  TimeEntry.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import SwiftData

@Model
final class TimeEntry {
    var id: String
    var employeeId: String
    var date: Date
    var hours: Double
    var projectId: String?
    var projectName: String?
    var taskId: String?
    var taskName: String?
    var note: String?
    var isSubmitted: Bool

    init(id: String = UUID().uuidString,
         employeeId: String,
         date: Date,
         hours: Double,
         projectId: String? = nil,
         projectName: String? = nil,
         taskId: String? = nil,
         taskName: String? = nil,
         note: String? = nil,
         isSubmitted: Bool = false) {
        self.id = id
        self.employeeId = employeeId
        self.date = date
        self.hours = hours
        self.projectId = projectId
        self.projectName = projectName
        self.taskId = taskId
        self.taskName = taskName
        self.note = note
        self.isSubmitted = isSubmitted
    }
}

// MARK: - Codable Extension
extension TimeEntry: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case employeeId
        case date
        case hours
        case note
        case projectInfo
        case type
        case timezone
        case approved
        case approvedAt
    }

    enum ProjectInfoKeys: String, CodingKey {
        case project
        case task
    }

    enum ProjectKeys: String, CodingKey {
        case id
        case name
    }

    enum TaskKeys: String, CodingKey {
        case id
        case name
    }

    // Root level keys for the request body (for encoding/submitting)
    enum RootKeys: String, CodingKey {
        case hours
    }

    // Keys for encoding when submitting time entries (different from response structure)
    enum SubmissionKeys: String, CodingKey {
        case employeeId
        case date
        case hours
        case note
        case projectId
        case taskId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Parse ID - API returns it as Int, we store as String
        let idInt = try container.decode(Int.self, forKey: .id)
        let id = String(idInt)

        // Parse employeeId as Int
        let employeeIdInt = try container.decode(Int.self, forKey: .employeeId)
        let employeeId = String(employeeIdInt)

        // Parse date string in YYYY-MM-DD format
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Date string does not match format")
        }

        let hours = try container.decode(Double.self, forKey: .hours)

        // Parse note - can be null in API
        let note = try container.decodeIfPresent(String.self, forKey: .note)

        // Parse nested projectInfo structure
        var projectId: String?
        var projectName: String?
        var taskId: String?
        var taskName: String?

        if let projectInfoContainer = try? container.nestedContainer(keyedBy: ProjectInfoKeys.self, forKey: .projectInfo) {
            // Parse project info
            if let projectContainer = try? projectInfoContainer.nestedContainer(keyedBy: ProjectKeys.self, forKey: .project) {
                let projectIdInt = try projectContainer.decode(Int.self, forKey: .id)
                projectId = String(projectIdInt)
                projectName = try projectContainer.decode(String.self, forKey: .name)
            }

            // Parse task info
            if let taskContainer = try? projectInfoContainer.nestedContainer(keyedBy: TaskKeys.self, forKey: .task) {
                let taskIdInt = try taskContainer.decode(Int.self, forKey: .id)
                taskId = String(taskIdInt)
                taskName = try taskContainer.decode(String.self, forKey: .name)
            }
        }

        self.init(
            id: id,
            employeeId: employeeId,
            date: date,
            hours: hours,
            projectId: projectId,
            projectName: projectName,
            taskId: taskId,
            taskName: taskName,
            note: note,
            isSubmitted: true // Since it's from API, it's already submitted
        )
    }

    func encode(to encoder: Encoder) throws {
        // Format date as YYYY-MM-DD
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        // Create the entry object with the required fields
        var rootContainer = encoder.container(keyedBy: RootKeys.self)
        var entriesArray = rootContainer.nestedUnkeyedContainer(forKey: .hours)

        var entryContainer = entriesArray.nestedContainer(keyedBy: SubmissionKeys.self)

        // Convert employeeId to Int
        if let employeeIdInt = Int(employeeId) {
            try entryContainer.encode(employeeIdInt, forKey: .employeeId)
        } else {
            throw EncodingError.invalidValue(employeeId, EncodingError.Context(
                codingPath: [RootKeys.hours, SubmissionKeys.employeeId],
                debugDescription: "employeeId must be a valid integer"
            ))
        }

        try entryContainer.encode(dateString, forKey: .date)
        try entryContainer.encode(hours, forKey: .hours)

        // Note can be nil, so use encodeIfPresent
        try entryContainer.encodeIfPresent(note, forKey: .note)

        // Convert projectId to Int if present
        if let projectId = projectId, let projectIdInt = Int(projectId) {
            try entryContainer.encode(projectIdInt, forKey: .projectId)
        } else if projectId != nil {
            throw EncodingError.invalidValue(projectId!, EncodingError.Context(
                codingPath: [RootKeys.hours, SubmissionKeys.projectId],
                debugDescription: "projectId must be a valid integer"
            ))
        }

        // Convert taskId to Int if present
        if let taskId = taskId, let taskIdInt = Int(taskId) {
            try entryContainer.encode(taskIdInt, forKey: .taskId)
        } else if taskId != nil {
            throw EncodingError.invalidValue(taskId!, EncodingError.Context(
                codingPath: [RootKeys.hours, SubmissionKeys.taskId],
                debugDescription: "taskId must be a valid integer"
            ))
        }
    }
}

@Model
final class Task {
    var id: String
    var name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Task Codable Extension
extension Task: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Convert numeric ID to string
        let idInt = try container.decode(Int.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)

        self.init(
            id: String(idInt),
            name: name
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Convert string ID to integer for API
        if let idInt = Int(id) {
            try container.encode(idInt, forKey: .id)
        }

        try container.encode(name, forKey: .name)
    }
}

@Model
final class Project {
    var id: String
    var name: String
    var tasks: [Task]
    var isActive: Bool

    init(id: String, name: String, tasks: [Task] = [], isActive: Bool = true) {
        self.id = id
        self.name = name
        self.tasks = tasks
        self.isActive = isActive
    }
}

// MARK: - Project Codable Extension
extension Project: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tasks
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Convert numeric ID to string
        let idInt = try container.decode(Int.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let tasks = try container.decode([Task].self, forKey: .tasks)

        self.init(
            id: String(idInt),
            name: name,
            tasks: tasks,
            isActive: true
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Convert string ID to integer for API
        if let idInt = Int(id) {
            try container.encode(idInt, forKey: .id)
        }

        try container.encode(name, forKey: .name)
        try container.encode(tasks, forKey: .tasks)
    }
}
