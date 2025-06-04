import Foundation

struct BambooLeaveInfo: Identifiable, Decodable {
    let id: Int
    let type: String
    let employeeId: Int?
    let name: String
    let start: String
    let end: String

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
}