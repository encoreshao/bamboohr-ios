import Foundation

struct BambooLeaveInfo: Identifiable, Decodable {
    let id: Int
    let type: String
    let employeeId: Int?
    let name: String
    let start: String
    let end: String
    var photoUrl: String?
    var status: String? // Add status field for request status (requested, approved, denied)

    // Custom initializer for creating from response data
    init(id: Int, type: String, employeeId: Int?, name: String, start: String, end: String, photoUrl: String? = nil, status: String? = nil) {
        self.id = id
        self.type = type
        self.employeeId = employeeId
        self.name = name
        self.start = start
        self.end = end
        self.photoUrl = photoUrl
        self.status = status
    }

    var startDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: start)
    }
    var endDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: end)
    }
    var leaveDuration: Int? {
        guard let startDate = startDate, let endDate = endDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1
    }
    var durationString: String {
        if let days = leaveDuration {
            return "\(days) day" + (days > 1 ? "s" : "")
        }
        return ""
    }
    // Computed fallback if photoUrl is nil
    func computedPhotoUrl(companyDomain: String) -> String? {
        guard let employeeId = employeeId else { return nil }
        return "https://api.bamboohr.com/api/gateway.php/\(companyDomain)/v1/employees/\(employeeId)/photo/large"
    }

    // MARK: - Conversion from TimeOffRequestResponse
    static func fromTimeOffRequest(_ request: TimeOffRequestResponse) -> BambooLeaveInfo {
        return BambooLeaveInfo(
            id: request.id,
            type: request.type,
            employeeId: request.employeeId,
            name: request.name,
            start: request.start,
            end: request.end,
            photoUrl: nil, // Will be populated from computed property
            status: extractStatus(from: request)
        )
    }

    private static func extractStatus(from request: TimeOffRequestResponse) -> String {
        // Determine status from available actions since the existing model doesn't have status field
        if request.actions.approve || request.actions.deny {
            return "requested" // Still pending approval (can be approved/denied)
        } else if request.actions.cancel || request.actions.edit {
            return "approved" // Approved but can still be modified/cancelled
        }

        // Default fallback
        return "requested"
    }
}