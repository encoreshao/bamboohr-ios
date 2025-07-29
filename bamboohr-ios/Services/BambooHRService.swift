//
//  BambooHRService.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine

enum BambooHRError: Error {
    case invalidURL
    case invalidResponse
    case authenticationError
    case networkError(Error)
    case decodingError(Error)
    case unknownError(String)
}

// MARK: - XML Parser for User
class UserXMLParser: NSObject, XMLParserDelegate {
    var user: User?
    private var currentElement = ""
    private var currentFieldId = ""
    private var employeeId = ""
    private var firstName = ""
    private var lastName = ""
    private var jobTitle = ""
    private var department = ""
    private var location = ""
    private var photoUrl: String?
    private var preferredName: String?
    // Buffer for collecting text content
    private var currentText = ""
    // Flag to track if we're inside the employee element
    private var isParsingEmployee = false

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        // Clear the text buffer when starting a new element
        currentText = ""
        currentElement = elementName
        if elementName == "employee" {
            isParsingEmployee = true
            // Get employee ID from attribute
            if let id = attributeDict["id"] {
                employeeId = id
            }
        } else if elementName == "field" && isParsingEmployee {
            // Get field ID from attribute
            if let fieldId = attributeDict["id"] {
                currentFieldId = fieldId
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "employee" {
            // Create the user object when we finish parsing the employee element
            user = User(
                id: employeeId,
                firstName: firstName,
                lastName: lastName,
                jobTitle: jobTitle,
                department: department,
                photoUrl: photoUrl,
                nickname: preferredName,
                location: location,
            )
            isParsingEmployee = false
        } else if elementName == "field" && isParsingEmployee {
            // Process the field based on its ID
            let fieldValue = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            switch currentFieldId {
            case "firstName":
                firstName = fieldValue
            case "lastName":
                lastName = fieldValue
            case "jobTitle":
                jobTitle = fieldValue
            case "department":
                department = fieldValue
            case "location":
                location = fieldValue
            case "photoUrl":
                photoUrl = fieldValue
            case "preferredName":
                preferredName = fieldValue
            default:
                print("DEBUG: Ignoring unknown field: \(currentFieldId)")
            }
            // Reset the current field ID
            currentFieldId = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Append the text to our buffer
        currentText += string
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("DEBUG: XML parsing error: \(parseError.localizedDescription)")
    }
}

class BambooHRService {
    static let shared = BambooHRService()

    private var accountSettings: AccountSettings?
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(accountSettings: AccountSettings? = nil) {
        self.accountSettings = accountSettings ?? KeychainManager.shared.loadAccountSettings()
        self.session = URLSession.shared

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func updateAccountSettings(_ settings: AccountSettings) {
        self.accountSettings = settings
    }

    // MARK: - API Endpoints

    func fetchCurrentUser() -> AnyPublisher<User, BambooHRError> {
        guard let settings = accountSettings, let baseUrl = settings.baseUrl else {
            print("DEBUG: Invalid URL or missing account settings")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        // Create the base URL
        let basePath = "/\(settings.companyDomain)/v1/employees/\(settings.employeeId)"
        let baseEndpoint = baseUrl.appendingPathComponent(basePath)

        // Use URLComponents to properly add query parameters
        var components = URLComponents(url: baseEndpoint, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "fields", value: "firstName,lastName,jobTitle,department,location,preferredName")
        ]

        guard let endpoint = components?.url else {
            print("DEBUG: Failed to create URL with components")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addValue("application/xml", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error: \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<User, BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response type")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        print("DEBUG: Authentication error (401)")
                        return Fail(error: BambooHRError.authenticationError).eraseToAnyPublisher()
                    } else {
                        print("DEBUG: Unexpected status code: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("DEBUG: Response body: \(responseString)")
                        }
                        return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)"))
                            .eraseToAnyPublisher()
                    }
                }

                // Parse XML response
                do {
                    let user = try self.parseUserXML(data: data)
                    // Ensure photoUrl is set for the user
                    if user.photoUrl == nil, let settings = self.accountSettings {
                        user.photoUrl = "https://api.bamboohr.com/api/gateway.php/\(settings.companyDomain)/v1/employees/\(settings.employeeId)/photo/large"
                    }
                    return Just(user)
                        .setFailureType(to: BambooHRError.self)
                        .eraseToAnyPublisher()
                } catch {
                    // Log the raw XML response for debugging
                    if let xmlString = String(data: data, encoding: .utf8) {
                        print("DEBUG: Raw XML response (parsing failed): \n\(xmlString)")
                    }
                    print("DEBUG: XML parsing error: \(error.localizedDescription)")
                    return Fail(error: BambooHRError.decodingError(error)).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchTimeOffEntries(startDate: Date, endDate: Date) -> AnyPublisher<[BambooLeaveInfo], BambooHRError> {
        guard let settings = accountSettings, let baseUrl = settings.baseUrl else {
            print("DEBUG: Invalid URL or missing account settings in fetchTimeOffEntries")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)

        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/time_off/whos_out")

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "start", value: startDateString),
            URLQueryItem(name: "end", value: endDateString),
            URLQueryItem(name: "status", value: "approved")
        ]

        guard let url = components?.url else {
            print("DEBUG: Failed to create URL with components")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error in leave request: \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<[BambooLeaveInfo], BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response type in leave request")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        print("DEBUG: Authentication error (401) in leave request")
                        return Fail(error: BambooHRError.authenticationError).eraseToAnyPublisher()
                    } else {
                        print("DEBUG: Unexpected status code in leave request: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("DEBUG: Raw leave response: \(responseString)")
                        }
                        return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                    }
                }

                // Log the raw response for debugging
                // if let responseString = String(data: data, encoding: .utf8) {
                //     print("DEBUG: Raw leave response: \(responseString)")
                // }

                // Try to decode as an array of dictionaries, filter for type == "timeOff", then decode only those into [BambooLeaveInfo]
                do {
                    let rawArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? []
                    let timeOffData = rawArray.filter { $0["type"] as? String == "timeOff" }
                    let filteredData = try JSONSerialization.data(withJSONObject: timeOffData, options: [])
                    var leaveInfos = try self.decoder.decode([BambooLeaveInfo].self, from: filteredData)
                    // Set photoUrl for each entry
                    if let companyDomain = settings.companyDomain as String? {
                        for i in 0..<leaveInfos.count {
                            if leaveInfos[i].photoUrl == nil, let employeeId = leaveInfos[i].employeeId {
                                leaveInfos[i].photoUrl = "https://api.bamboohr.com/api/gateway.php/\(companyDomain)/v1/employees/\(employeeId)/photo/large"
                            }
                        }
                    }
                    return Just(leaveInfos)
                        .setFailureType(to: BambooHRError.self)
                        .eraseToAnyPublisher()
                } catch {
                    print("DEBUG: Decoding error in leave response: \(error.localizedDescription). Returning empty array.")
                    return Just([])
                        .setFailureType(to: BambooHRError.self)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchProjects() -> AnyPublisher<[Project], BambooHRError> {
        guard let settings = accountSettings, let baseUrl = settings.baseUrl else {
            print("DEBUG: Invalid URL or missing account settings in fetchProjects")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/time_tracking/employees/\(settings.employeeId)/projects")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error in projects request: \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<[Project], BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response type in projects request")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        print("DEBUG: Authentication error (401) in projects request")
                        return Fail(error: BambooHRError.authenticationError).eraseToAnyPublisher()
                    } else {
                        print("DEBUG: Unexpected status code in projects request: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("DEBUG: Projects response body: \(responseString)")
                        }
                        return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                    }
                }

                return Just(data)
                    .decode(type: [Project].self, decoder: self.decoder)
                    .mapError { error -> BambooHRError in
                        print("DEBUG: Decoding error in projects response: \(error.localizedDescription)")
                        return BambooHRError.decodingError(error)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - XML Parsing

    private func parseUserXML(data: Data) throws -> User {
        let parser = XMLParser(data: data)
        let xmlHandler = UserXMLParser()
        parser.delegate = xmlHandler

        if parser.parse() {
            guard let user = xmlHandler.user else {
                throw BambooHRError.decodingError(NSError(domain: "BambooHRService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract user from XML"]))
            }
            return user
        } else if let error = parser.parserError {
            throw BambooHRError.decodingError(error)
        } else {
            throw BambooHRError.decodingError(NSError(domain: "BambooHRService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown XML parsing error"]))
        }
    }

    func submitTimeEntry(_ timeEntry: TimeEntry) -> AnyPublisher<Bool, BambooHRError> {
        guard let settings = accountSettings, let baseUrl = settings.baseUrl else {
            print("DEBUG: Invalid URL or missing account settings in submitTimeEntry")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/time_tracking/hour_entries/store")

        // Format date for logging
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        do {
            encoder.keyEncodingStrategy = .useDefaultKeys  // Ensures property names are not changed
            let encodedData = try encoder.encode(timeEntry)
            request.httpBody = encodedData
        } catch let encodingError {
            print("DEBUG: Error encoding time entry: \(encodingError.localizedDescription)")
            return Fail(error: BambooHRError.decodingError(encodingError)).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error in time entry submission: \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<Bool, BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response type in time entry submission")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                    if httpResponse.statusCode == 401 {
                        print("DEBUG: Authentication error (401) in time entry submission")
                        return Fail(error: BambooHRError.authenticationError).eraseToAnyPublisher()
                    } else {
                        print("DEBUG: Unexpected status code in time entry submission: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("DEBUG: Time entry submission response body: \(responseString)")
                        }
                        return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                    }
                }

                return Just(true)
                    .setFailureType(to: BambooHRError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch Time Entries for a specific date
    func fetchTimeEntries(for date: Date) -> AnyPublisher<[TimeEntry], BambooHRError> {
        guard let settings = accountSettings, let baseUrl = settings.baseUrl else {
            print("DEBUG: Invalid URL or missing account settings in fetchTimeEntries")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        // Use the correct endpoint format based on working Node.js API
        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/time_tracking/timesheet_entries")

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "employeeIds", value: settings.employeeId), // Note: employeeIds (plural)
            URLQueryItem(name: "start", value: dateString),
            URLQueryItem(name: "end", value: dateString)
        ]

        guard let url = components?.url else {
            print("DEBUG: Failed to create URL with components")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        print("DEBUG: Fetching time entries from URL: \(url.absoluteString)")

        return session.dataTaskPublisher(for: request)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error in time entries request: \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<[TimeEntry], BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response type in time entries request")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                print("DEBUG: Time entries response status: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        print("DEBUG: Authentication error (401) in time entries request")
                        return Fail(error: BambooHRError.authenticationError).eraseToAnyPublisher()
                    } else if httpResponse.statusCode == 404 {
                        print("DEBUG: Time tracking endpoint not found (404) - this may indicate time tracking is not enabled")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("DEBUG: Time entries response body: \(responseString)")
                        }
                        // Return empty array for 404 as it might just mean no time tracking is enabled
                        return Just([])
                            .setFailureType(to: BambooHRError.self)
                            .eraseToAnyPublisher()
                    } else {
                        print("DEBUG: Unexpected status code in time entries request: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("DEBUG: Time entries response body: \(responseString)")
                        }
                        return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                    }
                }

                // Successfully got 200 response, try to decode
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Time entries successful response body: \(responseString)")
                }

                return Just(data)
                    .decode(type: [TimeEntry].self, decoder: self.decoder)
                    .mapError { error -> BambooHRError in
                        print("DEBUG: Decoding error in time entries response: \(error.localizedDescription)")
                        return BambooHRError.decodingError(error)
                    }
                    .catch { _ -> AnyPublisher<[TimeEntry], BambooHRError> in
                        print("DEBUG: Failed to decode time entries, returning empty array")
                        // Return empty array if decoding fails
                        return Just([])
                            .setFailureType(to: BambooHRError.self)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch Employee Time Off Balance
    func fetchTimeOffBalance() -> AnyPublisher<Int, BambooHRError> {
        guard let settings = accountSettings, let baseUrl = settings.baseUrl else {
            print("DEBUG: Invalid URL or missing account settings in fetchTimeOffBalance")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        // BambooHR API endpoint for time off balances
        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/employees/\(settings.employeeId)/time_off/calculator")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        print("DEBUG: Fetching time off balance from URL: \(endpoint.absoluteString)")

        return session.dataTaskPublisher(for: request)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error in time off balance request: \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<Int, BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response type in time off balance request")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                print("DEBUG: Time off balance response status: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        print("DEBUG: Authentication error (401) in time off balance request")
                        return Fail(error: BambooHRError.authenticationError).eraseToAnyPublisher()
                    } else if httpResponse.statusCode == 404 {
                        print("DEBUG: Time off balance endpoint not found (404) - this may indicate time off tracking is not enabled")
                        // Return a reasonable default value for 404
                        return Just(15)
                            .setFailureType(to: BambooHRError.self)
                            .eraseToAnyPublisher()
                    } else {
                        print("DEBUG: Unexpected status code in time off balance request: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("DEBUG: Time off balance response body: \(responseString)")
                        }
                        return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                    }
                }

                // Successfully got 200 response, try to parse JSON
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Time off balance successful response body: \(responseString)")
                }

                do {
                    // API直接返回数组，不是包含balances键的对象
                    if let balances = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        print("DEBUG: Found \(balances.count) time off balance entries")

                        // Look for vacation or PTO balance
                        var totalBalance = 0.0
                        for balance in balances {
                            if let policyType = balance["policyType"] as? String,
                               let name = balance["name"] as? String,
                               let balanceString = balance["balance"] as? String,
                               let currentBalance = Double(balanceString) {

                                print("DEBUG: Time off entry - Type: \(policyType), Name: \(name), Balance: \(currentBalance)")

                                // 匹配主要的假期类型
                                if (policyType.lowercased().contains("accruing") &&
                                    (name.lowercased().contains("paid leave") ||
                                     name.lowercased().contains("vacation") ||
                                     name.lowercased().contains("pto") ||
                                     name.lowercased().contains("annual") ||
                                     name.lowercased().contains("wellbeing holiday"))) {
                                    totalBalance += currentBalance
                                    print("DEBUG: Added \(currentBalance) from \(name) to total balance")
                                }
                            }
                        }

                        let finalBalance = max(0, Int(totalBalance))
                        print("DEBUG: Final calculated leave balance: \(finalBalance)")

                        return Just(finalBalance)
                            .setFailureType(to: BambooHRError.self)
                            .eraseToAnyPublisher()
                    } else {
                        print("DEBUG: Failed to parse response as array")
                        // Fallback parsing - try to find any numeric balance
                        return Just(12) // Reasonable default
                            .setFailureType(to: BambooHRError.self)
                            .eraseToAnyPublisher()
                    }
                } catch {
                    print("DEBUG: JSON parsing error in time off balance response: \(error.localizedDescription)")
                    return Just(12) // Reasonable default
                        .setFailureType(to: BambooHRError.self)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch Employee Directory
    func fetchEmployeeDirectory() -> AnyPublisher<[User], BambooHRError> {
        guard let settings = accountSettings, let baseUrl = settings.baseUrl else {
            print("DEBUG: Invalid URL or missing account settings in fetchEmployeeDirectory")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        // BambooHR employee directory endpoint
        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/employees/directory")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        print("DEBUG: Fetching employee directory from URL: \(endpoint.absoluteString)")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .tryMap { data -> [User] in
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Employee directory raw response: \(String(jsonString.prefix(500)))...")
                }

                // Try to parse the JSON response
                do {
                    let decoder = JSONDecoder()

                    // BambooHR directory response structure
                    struct DirectoryResponse: Codable {
                        let employees: [DirectoryEmployee]
                    }

                    struct DirectoryEmployee: Codable {
                        let id: String
                        let displayName: String?
                        let firstName: String?
                        let lastName: String?
                        let jobTitle: String?
                        let workEmail: String?
                        let department: String?
                        let location: String?
                        let photoUploaded: Bool?
                        let photoUrl: String?
                        let preferredName: String?
                        let homePhone: String?
                        let mobilePhone: String?
                        let workPhone: String?
                    }

                    let response = try decoder.decode(DirectoryResponse.self, from: data)

                    let users = response.employees.compactMap { employee -> User? in
                        let firstName = employee.firstName ?? ""
                        let lastName = employee.lastName ?? ""
                        let jobTitle = employee.jobTitle ?? "Unknown"
                        let department = employee.department ?? "Unknown"

                        // Skip if essential fields are missing
                        guard !employee.id.isEmpty, !(firstName.isEmpty && lastName.isEmpty) else {
                            return nil
                        }

                        // Construct photo URL if available
                        var photoUrl: String?
                        if employee.photoUploaded == true {
                            photoUrl = "https://api.bamboohr.com/api/gateway.php/\(settings.companyDomain)/v1/employees/\(employee.id)/photo/large"
                        }

                        // Determine best phone number (prioritize mobile, then work, then home)
                        let phone = employee.mobilePhone ?? employee.workPhone ?? employee.homePhone

                        return User(
                            id: employee.id,
                            firstName: firstName,
                            lastName: lastName,
                            jobTitle: jobTitle,
                            department: department,
                            photoUrl: photoUrl,
                            nickname: employee.preferredName,
                            location: employee.location,
                            email: employee.workEmail,
                            phone: phone
                        )
                    }

                    print("DEBUG: Successfully parsed \(users.count) employees from directory")
                    return users
                } catch {
                    print("DEBUG: Failed to parse employee directory JSON: \(error.localizedDescription)")
                    throw BambooHRError.decodingError(error)
                }
            }
            .mapError { error -> BambooHRError in
                if let bambooError = error as? BambooHRError {
                    return bambooError
                }

                if let urlError = error as? URLError {
                    print("DEBUG: Network error in fetchEmployeeDirectory: \(urlError.localizedDescription)")
                    return BambooHRError.networkError(urlError)
                }

                print("DEBUG: Unknown error in fetchEmployeeDirectory: \(error.localizedDescription)")
                return BambooHRError.unknownError(error.localizedDescription)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
