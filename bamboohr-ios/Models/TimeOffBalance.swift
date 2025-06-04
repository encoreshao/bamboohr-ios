import Foundation

struct TimeOffBalance: Identifiable, Decodable {
    var id: String { type }
    let type: String        // e.g., "vacation", "sick", "personal"
    let name: String        // e.g., "Vacation", "Sick Leave"
    let balance: Double     // e.g., 10.5
    let units: String?      // e.g., "days" or "hours"
    let lastUpdated: String? // Optional, if present in API
}