//
//  BambooHRService.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import Combine

// MARK: - Data Structures for Two-Step Celebrations Fetch

struct EmployeeBasicInfo {
    let id: String
    let firstName: String?
    let lastName: String?
    let department: String?
}

struct EmployeeDetailInfo {
    let id: String
    let firstName: String
    let lastName: String
    let department: String?
    let hireDate: String?
    let dateOfBirth: String?
    let photoUrl: String?
    let preferredName: String?

    // Computed property for display name (similar to User.fullName)
    var displayName: String {
        if let preferredName = preferredName, !preferredName.isEmpty {
            return "\(preferredName) \(lastName)"
        } else {
            return "\(firstName) \(lastName)"
        }
    }
}

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
    private var email: String?
    private var phone: String?
    private var hireDate: String?
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
                email: email,
                phone: phone,
                hireDate: hireDate
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
            case "email":
                email = fieldValue
            case "phone":
                phone = fieldValue
            case "hireDate":
                hireDate = fieldValue
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

// MARK: - XML Parser for Employee Detail
class EmployeeDetailXMLParser: NSObject, XMLParserDelegate {
    var firstName = ""
    var lastName = ""
    var department: String?
    var hireDate: String?
    var dateOfBirth: String?
    var photoUrl: String?
    var preferredName: String?

    private var currentElement = ""
    private var currentFieldId = ""
    private var currentText = ""
    private var isParsingEmployee = false

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentText = ""
        currentElement = elementName

        if elementName == "employee" {
            isParsingEmployee = true
        } else if elementName == "field" && isParsingEmployee {
            if let fieldId = attributeDict["id"] {
                currentFieldId = fieldId
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "field" && isParsingEmployee {
            let fieldValue = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            switch currentFieldId {
            case "firstName":
                firstName = fieldValue
            case "lastName":
                lastName = fieldValue
            case "department":
                department = fieldValue.isEmpty ? nil : fieldValue
            case "hireDate":
                hireDate = fieldValue.isEmpty ? nil : fieldValue
            case "dateOfBirth":
                dateOfBirth = fieldValue.isEmpty ? nil : fieldValue
            case "photoUrl":
                photoUrl = fieldValue.isEmpty ? nil : fieldValue
            case "preferredName":
                preferredName = fieldValue.isEmpty ? nil : fieldValue
            default:
                break
            }
            currentFieldId = ""
        } else if elementName == "employee" {
            isParsingEmployee = false
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("DEBUG: Employee detail XML parsing error: \(parseError.localizedDescription)")
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
            URLQueryItem(name: "fields", value: "firstName,lastName,jobTitle,department,location,preferredName,email,phone,hireDate,photoUrl")
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
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return fetchTimeEntries(from: startOfDay, to: startOfDay)
    }

    // MARK: - Fetch Time Entries for a date range
    func fetchTimeEntries(from startDate: Date, to endDate: Date) -> AnyPublisher<[TimeEntry], BambooHRError> {
        guard let settings = accountSettings, let baseUrl = settings.baseUrl else {
            print("DEBUG: Invalid URL or missing account settings in fetchTimeEntries")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)

        // Use the correct endpoint format based on working Node.js API
        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/time_tracking/timesheet_entries")

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "employeeIds", value: settings.employeeId), // Note: employeeIds (plural)
            URLQueryItem(name: "start", value: startDateString),
            URLQueryItem(name: "end", value: endDateString)
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

        print("DEBUG: Fetching time entries from \(startDateString) to \(endDateString) from URL: \(url.absoluteString)")

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
                        let hireDate: String?
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
                        let hireDate = employee.hireDate ?? ""

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
                            phone: phone,
                            hireDate: hireDate
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

    // MARK: - Submit Time Off Request
    func submitTimeOffRequest(_ request: TimeOffRequest) -> AnyPublisher<Bool, BambooHRError> {
        guard let settings = accountSettings, let baseUrl = settings.baseUrl else {
            print("DEBUG: Invalid URL or missing account settings in submitTimeOffRequest")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/time_off/requests")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        urlRequest.addValue(authString, forHTTPHeaderField: "Authorization")

        do {
            encoder.keyEncodingStrategy = .useDefaultKeys
            let encodedData = try encoder.encode(request)
            urlRequest.httpBody = encodedData

            if let requestString = String(data: encodedData, encoding: .utf8) {
                print("DEBUG: Time off request payload: \(requestString)")
            }
        } catch let encodingError {
            print("DEBUG: Error encoding time off request: \(encodingError.localizedDescription)")
            return Fail(error: BambooHRError.decodingError(encodingError)).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: urlRequest)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error in time off request submission: \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<Bool, BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response type in time off request submission")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                print("DEBUG: Time off request response status: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                    if httpResponse.statusCode == 401 {
                        print("DEBUG: Authentication error (401) in time off request submission")
                        return Fail(error: BambooHRError.authenticationError).eraseToAnyPublisher()
                    } else {
                        print("DEBUG: Unexpected status code in time off request submission: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("DEBUG: Time off request response body: \(responseString)")
                        }
                        return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                    }
                }

                // Log successful response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Time off request successful response: \(responseString)")
                }

                return Just(true)
                    .setFailureType(to: BambooHRError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Celebrations
    func fetchCelebrations() -> AnyPublisher<[Celebration], BambooHRError> {
        // Try to reload account settings if not available
        if accountSettings == nil {
            print("DEBUG: No account settings found, attempting to reload from keychain")
            accountSettings = KeychainManager.shared.loadAccountSettings()
        }

        guard let settings = accountSettings, let baseUrl = settings.baseUrl else {
            print("DEBUG: No valid account settings found for celebrations API")
            print("DEBUG: Available settings: companyDomain=\(accountSettings?.companyDomain ?? "nil"), apiKey=\(accountSettings?.apiKey.isEmpty == false ? "present" : "nil"), baseUrl=\(accountSettings?.baseUrl?.absoluteString ?? "nil")")

            // Still fallback to sample data, but with clear logging
            print("DEBUG: Using sample celebration data - configure BambooHR credentials to load real data")
            return Just(generateCelebrations())
                .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()
        }

        print("DEBUG: Using new two-step BambooHR API approach for celebrations data")
        print("DEBUG: Company domain: \(settings.companyDomain)")
        print("DEBUG: Base URL: \(baseUrl.absoluteString)")

        // New two-step approach
        return fetchAllEmployeesRecords(settings: settings, baseUrl: baseUrl)
            .flatMap { employees -> AnyPublisher<[Celebration], BambooHRError> in
                print("DEBUG: Step 1 complete - fetched \(employees.count) employee records")
                return self.fetchEmployeesDetailsForCelebrations(employees: employees, settings: settings, baseUrl: baseUrl)
            }
            .catch { error -> AnyPublisher<[Celebration], BambooHRError> in
                print("DEBUG: Two-step API approach failed: \(error)")
                print("DEBUG: Falling back to legacy approach")
                return self.fetchEmployeeCelebrationData(settings: settings, baseUrl: baseUrl)
                    .catch { legacyError -> AnyPublisher<[Celebration], BambooHRError> in
                        print("DEBUG: Legacy approach also failed: \(legacyError)")
                        print("DEBUG: Using sample celebration data as final fallback")
                        return Just(self.generateCelebrations())
                            .setFailureType(to: BambooHRError.self)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Step 1: Fetch All Employee Records
    private func fetchAllEmployeesRecords(settings: AccountSettings, baseUrl: URL) -> AnyPublisher<[EmployeeBasicInfo], BambooHRError> {
        print("DEBUG: Step 1 - Fetching all employee records from directory")

        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/employees/directory")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        print("DEBUG: Fetching employee directory from: \(endpoint.absoluteString)")

        return session.dataTaskPublisher(for: request)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error in fetchAllEmployeesRecords: \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<[EmployeeBasicInfo], BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response type in fetchAllEmployeesRecords")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                print("DEBUG: Employee records response status: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        print("DEBUG: Authentication error (401) in fetchAllEmployeesRecords")
                        return Fail(error: BambooHRError.authenticationError).eraseToAnyPublisher()
                    } else {
                        print("DEBUG: Unexpected status code in fetchAllEmployeesRecords: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("DEBUG: Employee records response body: \(responseString)")
                        }
                        return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                    }
                }

                return self.parseEmployeeBasicInfo(data: data)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Step 2: Fetch Individual Employee Details for Celebrations
    private func fetchEmployeesDetailsForCelebrations(employees: [EmployeeBasicInfo], settings: AccountSettings, baseUrl: URL) -> AnyPublisher<[Celebration], BambooHRError> {
        print("DEBUG: Step 2 - Fetching detailed information for \(employees.count) employees")

        // Create individual requests for each employee to get their hireDate and dateOfBirth
        let detailPublishers = employees.map { employee in
            fetchEmployeeDetailWithFallback(basicInfo: employee, settings: settings, baseUrl: baseUrl)
        }

        // Execute all requests concurrently and wait for all to complete
        return Publishers.MergeMany(detailPublishers)
            .collect()
            .map { employeeDetails -> [Celebration] in
                print("DEBUG: Step 2 complete - fetched details for \(employeeDetails.count) employees")

                // Log how many employees have valid vs empty data
                let validEmployees = employeeDetails.filter { !$0.displayName.trimmingCharacters(in: .whitespaces).isEmpty }
                let emptyEmployees = employeeDetails.filter { $0.displayName.trimmingCharacters(in: .whitespaces).isEmpty }

                print("DEBUG: Valid employee details: \(validEmployees.count)")
                print("DEBUG: Empty/failed employee details: \(emptyEmployees.count)")

                if !emptyEmployees.isEmpty {
                    print("DEBUG: Failed employee IDs: \(emptyEmployees.map { $0.id }.joined(separator: ", "))")
                }

                return self.generateCelebrationsFromEmployeeDetails(employeeDetails)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch Individual Employee Detail with Fallback
    private func fetchEmployeeDetailWithFallback(basicInfo: EmployeeBasicInfo, settings: AccountSettings, baseUrl: URL) -> AnyPublisher<EmployeeDetailInfo, BambooHRError> {
        return fetchEmployeeDetailWithRetry(employeeId: basicInfo.id, settings: settings, baseUrl: baseUrl, retryCount: 2)
            .map { detailInfo -> EmployeeDetailInfo in
                // If we got an empty result, create a fallback using basic info
                if detailInfo.displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                    print("DEBUG: Using fallback basic info for employee \(basicInfo.id)")
                    return EmployeeDetailInfo(
                        id: basicInfo.id,
                        firstName: basicInfo.firstName ?? "",
                        lastName: basicInfo.lastName ?? "",
                        department: basicInfo.department,
                        hireDate: nil, // No hire date available from basic info
                        dateOfBirth: nil, // No birth date available from basic info
                        photoUrl: nil, // No photo URL available from basic info
                        preferredName: nil // No preferred name available from basic info
                    )
                } else {
                    return detailInfo
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch Individual Employee Detail
    private func fetchEmployeeDetail(employeeId: String, settings: AccountSettings, baseUrl: URL) -> AnyPublisher<EmployeeDetailInfo, BambooHRError> {
        return fetchEmployeeDetailWithRetry(employeeId: employeeId, settings: settings, baseUrl: baseUrl, retryCount: 2)
    }

    // Helper method with retry logic
    private func fetchEmployeeDetailWithRetry(employeeId: String, settings: AccountSettings, baseUrl: URL, retryCount: Int) -> AnyPublisher<EmployeeDetailInfo, BambooHRError> {
        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/employees/\(employeeId)")

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "fields", value: "firstName,lastName,department,jobTitle,hireDate,dateOfBirth,preferredName,photoUrl")
        ]

        guard let url = components?.url else {
            print("DEBUG: Failed to create employee detail URL for employee \(employeeId)")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/xml", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error fetching employee \(employeeId): \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<EmployeeDetailInfo, BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response for employee \(employeeId)")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                guard httpResponse.statusCode == 200 else {
                    print("DEBUG: Failed to fetch employee \(employeeId) - status: \(httpResponse.statusCode), retries left: \(retryCount)")

                    // If we have retries left and it's a temporary error, retry
                    if retryCount > 0 && (httpResponse.statusCode >= 500 || httpResponse.statusCode == 429) {
                        print("DEBUG: Retrying employee \(employeeId) API call in 1 second...")
                        return Just(())
                            .delay(for: .seconds(1), scheduler: DispatchQueue.global())
                            .flatMap { _ in
                                self.fetchEmployeeDetailWithRetry(employeeId: employeeId, settings: settings, baseUrl: baseUrl, retryCount: retryCount - 1)
                            }
                            .eraseToAnyPublisher()
                    }

                    // If no retries left or permanent error, return empty detail
                    print("DEBUG: No more retries for employee \(employeeId) or permanent error")
                    let emptyDetail = EmployeeDetailInfo(
                        id: employeeId,
                        firstName: "",
                        lastName: "",
                        department: nil,
                        hireDate: nil,
                        dateOfBirth: nil,
                        photoUrl: nil,
                        preferredName: nil
                    )
                    return Just(emptyDetail)
                        .setFailureType(to: BambooHRError.self)
                        .eraseToAnyPublisher()
                }

                return self.parseEmployeeDetailXML(data: data, employeeId: employeeId)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Parse Employee Basic Info from Directory
    private func parseEmployeeBasicInfo(data: Data) -> AnyPublisher<[EmployeeBasicInfo], BambooHRError> {
        do {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG: Employee basic info response: \(String(jsonString.prefix(300)))...")
            }

            var employeeData: [[String: Any]] = []

            // Try parsing as directory response with employees array
            if let responseObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let employees = responseObject["employees"] as? [[String: Any]] {
                employeeData = employees
                print("DEBUG: Parsed basic info as response object with \(employeeData.count) employees")
            }
            // Try parsing as array directly
            else if let directArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                employeeData = directArray
                print("DEBUG: Parsed basic info as direct array with \(employeeData.count) employees")
            }

            let employees = employeeData.compactMap { employee -> EmployeeBasicInfo? in
                guard let id = employee["id"] as? String, !id.isEmpty else { return nil }

                return EmployeeBasicInfo(
                    id: id,
                    firstName: employee["firstName"] as? String,
                    lastName: employee["lastName"] as? String,
                    department: employee["department"] as? String
                )
            }

            print("DEBUG: Successfully parsed \(employees.count) employee basic records")
            return Just(employees)
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()

        } catch {
            print("DEBUG: Failed to parse employee basic info: \(error.localizedDescription)")
            return Fail(error: BambooHRError.decodingError(error)).eraseToAnyPublisher()
        }
    }

    // MARK: - Parse Employee Detail XML
    private func parseEmployeeDetailXML(data: Data, employeeId: String) -> AnyPublisher<EmployeeDetailInfo, BambooHRError> {
        if let xmlString = String(data: data, encoding: .utf8) {
            print("DEBUG: Employee \(employeeId) XML response: \(String(xmlString.prefix(300)))...")
        }

        let parser = XMLParser(data: data)
        let xmlHandler = EmployeeDetailXMLParser()
        parser.delegate = xmlHandler

        if parser.parse() {
                let detail = EmployeeDetailInfo(
                    id: employeeId,
                    firstName: xmlHandler.firstName,
                    lastName: xmlHandler.lastName,
                    department: xmlHandler.department,
                    hireDate: xmlHandler.hireDate,
                    dateOfBirth: xmlHandler.dateOfBirth,
                    photoUrl: xmlHandler.photoUrl,
                    preferredName: xmlHandler.preferredName
                )
            print("DEBUG: Successfully parsed details for employee \(employeeId)")
            return Just(detail)
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()
        } else {
            print("DEBUG: Failed to parse XML for employee \(employeeId)")
            let emptyDetail = EmployeeDetailInfo(
                id: employeeId,
                firstName: "",
                lastName: "",
                department: nil,
                hireDate: nil,
                dateOfBirth: nil,
                photoUrl: nil,
                preferredName: nil
            )
            return Just(emptyDetail)
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Generate Celebrations from Employee Details
    private func generateCelebrationsFromEmployeeDetails(_ employeeDetails: [EmployeeDetailInfo]) -> [Celebration] {
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var celebrations: [Celebration] = []

        print("DEBUG: Generating celebrations from \(employeeDetails.count) employee details")

        for employee in employeeDetails {
            let displayName = employee.displayName.trimmingCharacters(in: .whitespaces)

            // Skip if name is empty
            guard !displayName.isEmpty else {
                print("DEBUG: Skipping employee with empty name: \(employee.id)")
                continue
            }

            print("DEBUG: Processing employee: \(displayName) (ID: \(employee.id))")

            // Parse birthday
            if let birthdayStr = employee.dateOfBirth,
               !birthdayStr.isEmpty,
               let birthDate = dateFormatter.date(from: birthdayStr) {
                if let nextBirthday = getNextOccurrence(of: birthDate, from: today, within: 1) {
                    // Construct profile image URL if photoUrl is not available but employee ID is available
                    var profileImageUrl = employee.photoUrl
                    if profileImageUrl == nil || profileImageUrl?.isEmpty == true {
                        if let settings = accountSettings {
                            profileImageUrl = "https://api.bamboohr.com/api/gateway.php/\(settings.companyDomain)/v1/employees/\(employee.id)/photo/large"
                        }
                    }

                    celebrations.append(Celebration(
                        employeeId: employee.id,
                        employeeName: displayName,
                        type: .birthday,
                        date: nextBirthday,
                        department: employee.department,
                        profileImageUrl: profileImageUrl
                    ))
                    print("DEBUG: Added birthday celebration for \(displayName) on \(nextBirthday)")
                }
            } else {
                if employee.dateOfBirth == nil || employee.dateOfBirth?.isEmpty == true {
                    print("DEBUG: No birthday data for employee: \(displayName)")
                }
            }

            // Parse work anniversary
            if let hireDateStr = employee.hireDate,
               !hireDateStr.isEmpty,
               let hireDate = dateFormatter.date(from: hireDateStr) {
                if let nextAnniversary = getNextOccurrence(of: hireDate, from: today, within: 1) {
                    let yearsWorked = calendar.dateComponents([.year], from: hireDate, to: nextAnniversary).year ?? 0

                    // Construct profile image URL if photoUrl is not available but employee ID is available
                    var profileImageUrl = employee.photoUrl
                    if profileImageUrl == nil || profileImageUrl?.isEmpty == true {
                        if let settings = accountSettings {
                            profileImageUrl = "https://api.bamboohr.com/api/gateway.php/\(settings.companyDomain)/v1/employees/\(employee.id)/photo/large"
                        }
                    }

                    celebrations.append(Celebration(
                        employeeId: employee.id,
                        employeeName: displayName,
                        type: .workAnniversary,
                        date: nextAnniversary,
                        yearsCount: yearsWorked,
                        department: employee.department,
                        profileImageUrl: profileImageUrl
                    ))
                    print("DEBUG: Added work anniversary for \(displayName) on \(nextAnniversary) (\(yearsWorked) years)")
                }
            } else {
                if employee.hireDate == nil || employee.hireDate?.isEmpty == true {
                    print("DEBUG: No hire date data for employee: \(displayName)")
                }
            }
        }

        // Sort by date
        celebrations.sort { $0.date < $1.date }

        print("DEBUG: Generated \(celebrations.count) celebrations from employee details")
        return celebrations
    }

        // MARK: - Enhanced Employee Data Fetch with Birthday/Hire Date
    private func fetchEmployeeCelebrationData(settings: AccountSettings, baseUrl: URL) -> AnyPublisher<[Celebration], BambooHRError> {
        // Use the employees directory endpoint to get ALL employees with specific fields
        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/employees/directory")

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "fields", value: "id,firstName,lastName,department,dateOfBirth,hireDate,jobTitle,location,photoUrl,preferredName,email,phone,workPhone,homePhone"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components?.url else {
            print("DEBUG: Failed to create celebration data URL")
            return Fail(error: BambooHRError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        print("DEBUG: Fetching enhanced employee data for celebrations from: \(url.absoluteString)")

        return session.dataTaskPublisher(for: request)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error in fetchEmployeeCelebrationData: \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<[Celebration], BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response type in fetchEmployeeCelebrationData")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                print("DEBUG: Enhanced celebration data response status: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    print("DEBUG: Enhanced employee endpoint failed with status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("DEBUG: Enhanced response body: \(responseString)")
                    }
                    return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                }

                return self.parseEnhancedEmployeeData(data: data, companyDomain: settings.companyDomain)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Fallback Directory Fetch
    private func fetchCelebrationsFromDirectory(settings: AccountSettings, baseUrl: URL) -> AnyPublisher<[Celebration], BambooHRError> {
        print("DEBUG: Attempting to fetch celebrations from employee directory endpoint")
        // Fetch employee directory with birthday and hire date information
        let endpoint = baseUrl.appendingPathComponent("/\(settings.companyDomain)/v1/employees/directory")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add Basic Authentication
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")

        print("DEBUG: Fetching celebrations from employee directory URL: \(endpoint.absoluteString)")

        return session.dataTaskPublisher(for: request)
            .mapError { error -> BambooHRError in
                print("DEBUG: Network error in fetchCelebrations: \(error.localizedDescription)")
                return BambooHRError.networkError(error)
            }
            .flatMap { data, response -> AnyPublisher<[Celebration], BambooHRError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response type in fetchCelebrationsFromDirectory")
                    return Fail(error: BambooHRError.invalidResponse).eraseToAnyPublisher()
                }

                print("DEBUG: Directory celebrations response status: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        print("DEBUG: Authentication error (401) in fetchCelebrationsFromDirectory")
                        return Fail(error: BambooHRError.authenticationError).eraseToAnyPublisher()
                    } else if httpResponse.statusCode == 404 {
                        print("DEBUG: Employee directory endpoint not found (404) - falling back to sample data")
                        return Just(self.generateCelebrations())
                            .setFailureType(to: BambooHRError.self)
                            .eraseToAnyPublisher()
                    } else {
                        print("DEBUG: Unexpected status code in fetchCelebrationsFromDirectory: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("DEBUG: Directory celebrations response body: \(responseString)")
                        }
                        return Just(self.generateCelebrations())
                            .setFailureType(to: BambooHRError.self)
                            .eraseToAnyPublisher()
                    }
                }

                // Try to parse real employee data and extract celebrations
                return self.parseCelebrationsFromEmployeeData(data: data, companyDomain: settings.companyDomain)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Parse Enhanced Employee Data
    private func parseEnhancedEmployeeData(data: Data, companyDomain: String) -> AnyPublisher<[Celebration], BambooHRError> {
        do {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG: Enhanced employee data response: \(String(jsonString.prefix(500)))...")
            }

            // Try to parse as different possible formats
            var employeeData: [[String: Any]] = []

            // Try parsing as array directly
            if let directArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                employeeData = directArray
                print("DEBUG: Parsed enhanced data as direct array with \(employeeData.count) employees")
            }
            // Try parsing as response object
            else if let responseObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let employees = responseObject["employees"] as? [[String: Any]] {
                employeeData = employees
                print("DEBUG: Parsed enhanced data as response object with \(employeeData.count) employees")
            }
            // Try parsing as single employee (for specific ID queries)
            else if let singleEmployee = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                employeeData = [singleEmployee]
                print("DEBUG: Parsed enhanced data as single employee")
            }

            return self.processEmployeesForCelebrations(employeesData: employeeData, companyDomain: companyDomain)

        } catch {
            print("DEBUG: Failed to parse enhanced employee data: \(error.localizedDescription)")
            return Just(generateCelebrations())
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Parse Real Employee Data for Celebrations
    private func parseCelebrationsFromEmployeeData(data: Data, companyDomain: String) -> AnyPublisher<[Celebration], BambooHRError> {
        do {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG: Employee directory response for celebrations: \(String(jsonString.prefix(500)))...")
            }

            // Try to parse as different possible directory formats
            var employeeData: [[String: Any]] = []

            // Try parsing as directory response with employees array
            if let responseObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let employees = responseObject["employees"] as? [[String: Any]] {
                employeeData = employees
                print("DEBUG: Parsed directory data as response object with \(employeeData.count) employees")
            }
            // Try parsing as array directly
            else if let directArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                employeeData = directArray
                print("DEBUG: Parsed directory data as direct array with \(employeeData.count) employees")
            }

            return self.processEmployeesForCelebrations(employeesData: employeeData, companyDomain: companyDomain)

        } catch {
            print("DEBUG: Failed to parse employee data for celebrations: \(error.localizedDescription)")
            return Just(generateCelebrations())
                .setFailureType(to: BambooHRError.self)
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Process Employee Data into Celebrations
    private func processEmployeesForCelebrations(employeesData: [[String: Any]], companyDomain: String) -> AnyPublisher<[Celebration], BambooHRError> {
        let calendar = Calendar.current
        let today = Date()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var celebrations: [Celebration] = []

        print("DEBUG: Processing \(employeesData.count) employees for celebrations")

        for employee in employeesData {
            // Extract employee data
            guard let employeeId = employee["id"] as? String else { continue }

            let firstName = employee["firstName"] as? String ?? ""
            let lastName = employee["lastName"] as? String ?? ""
            let preferredName = employee["preferredName"] as? String

            // Construct display name using same logic as EmployeeDetailInfo
            let displayName: String
            if let preferredName = preferredName, !preferredName.isEmpty {
                displayName = "\(preferredName) \(lastName)"
            } else {
                displayName = "\(firstName) \(lastName)"
            }
            let finalDisplayName = displayName.trimmingCharacters(in: .whitespaces)

            // Skip if name is empty
            guard !finalDisplayName.isEmpty else { continue }

            let department = employee["department"] as? String

            // Get profile image URL
            let photoUrl = employee["photoUrl"] as? String
            let profileImageUrl = photoUrl ?? "https://api.bamboohr.com/api/gateway.php/\(companyDomain)/v1/employees/\(employeeId)/photo/large"

            // Parse birthday - try multiple possible field names
            let birthdayFields = ["dateOfBirth", "birthDate", "birthday"]
            for field in birthdayFields {
                if let birthdayStr = employee[field] as? String,
                   let birthDate = dateFormatter.date(from: birthdayStr) {
                    if let nextBirthday = getNextOccurrence(of: birthDate, from: today, within: 1) {
                        celebrations.append(Celebration(
                            employeeId: employeeId,
                            employeeName: finalDisplayName,
                            type: .birthday,
                            date: nextBirthday,
                            department: department,
                            profileImageUrl: profileImageUrl
                        ))
                        print("DEBUG: Added birthday celebration for \(finalDisplayName) on \(nextBirthday)")
                    }
                    break // Found birthday, no need to check other fields
                }
            }

            // Parse work anniversary - try multiple possible field names
            let hireDateFields = ["hireDate", "startDate", "dateOfHire", "employmentStartDate"]
            for field in hireDateFields {
                if let hireDateStr = employee[field] as? String,
                   let hireDate = dateFormatter.date(from: hireDateStr) {
                    if let nextAnniversary = getNextOccurrence(of: hireDate, from: today, within: 1) {
                        let yearsWorked = calendar.dateComponents([.year], from: hireDate, to: nextAnniversary).year ?? 0
                        celebrations.append(Celebration(
                            employeeId: employeeId,
                            employeeName: finalDisplayName,
                            type: .workAnniversary,
                            date: nextAnniversary,
                            yearsCount: yearsWorked,
                            department: department,
                            profileImageUrl: profileImageUrl
                        ))
                        print("DEBUG: Added work anniversary for \(finalDisplayName) on \(nextAnniversary) (\(yearsWorked) years)")
                    }
                    break // Found hire date, no need to check other fields
                }
            }
        }

        // Sort by date
        celebrations.sort { $0.date < $1.date }

        print("DEBUG: Successfully processed \(celebrations.count) celebrations from employee data")

        // Return real celebrations even if empty - let the main method handle fallback
        if celebrations.isEmpty {
            print("DEBUG: No real celebrations found in employee data for the next month")
        }

        return Just(celebrations)
            .setFailureType(to: BambooHRError.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Sample Employee Data for Fallback
    private let employees: [(String, String, String, String)] = [
        ("Alice Johnson", "Engineering", "1990-03-15", "2018-02-10"),
        ("Bob Smith", "Marketing", "1985-07-22", "2016-05-15"),
        ("Carol Davis", "HR", "1992-11-08", "2019-08-20"),
        ("David Wilson", "Sales", "1988-01-30", "2017-03-05"),
        ("Emma Brown", "Design", "1991-09-12", "2020-01-15"),
        ("Frank Miller", "Engineering", "1987-05-18", "2015-09-10"),
        ("Grace Lee", "Finance", "1993-02-28", "2021-04-12"),
        ("Henry Taylor", "Operations", "1989-12-05", "2016-11-08")
    ]

    private func generateCelebrations() -> [Celebration] {
        // Generate sample celebrations for the next month
        let calendar = Calendar.current
        let today = Date()
        var celebrations: [Celebration] = []

        // 🎉 Add a special birthday celebration for today!
        celebrations.append(Celebration(
            employeeId: "000",
            employeeName: "You", // This represents the current user
            type: .birthday,
            date: today,
            department: "🎂 Happy Birthday!"
        ))

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for (index, employeeData) in employees.enumerated() {
            let (name, department, birthdayStr, hireDateStr) = employeeData
            let employeeId = String(format: "%03d", index + 1)

            // Calculate next birthday in the next month
            if let birthDate = dateFormatter.date(from: birthdayStr) {
                let nextBirthday = getNextOccurrence(of: birthDate, from: today, within: 1)
                if let nextBirthday = nextBirthday {
                    celebrations.append(Celebration(
                        employeeId: employeeId,
                        employeeName: name,
                        type: .birthday,
                        date: nextBirthday,
                        department: department
                    ))
                }
            }

            // Calculate next work anniversary in the next month
            if let hireDate = dateFormatter.date(from: hireDateStr) {
                let nextAnniversary = getNextOccurrence(of: hireDate, from: today, within: 1)
                if let nextAnniversary = nextAnniversary {
                    let yearsWorked = calendar.dateComponents([.year], from: hireDate, to: nextAnniversary).year ?? 0
                    celebrations.append(Celebration(
                        employeeId: employeeId,
                        employeeName: name,
                        type: .workAnniversary,
                        date: nextAnniversary,
                        yearsCount: yearsWorked,
                        department: department
                    ))
                }
            }
        }

        // Sort by date
        return celebrations.sorted { $0.date < $1.date }
    }

    private func getNextOccurrence(of date: Date, from startDate: Date, within months: Int) -> Date? {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .month, value: months, to: startDate) ?? startDate

        // Get the month and day from the original date
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else { return nil }

        // Check this year's occurrence
        let currentYear = calendar.component(.year, from: startDate)
        if let thisYearDate = calendar.date(from: DateComponents(year: currentYear, month: month, day: day)),
           thisYearDate >= startDate && thisYearDate <= endDate {
            return thisYearDate
        }

        // Check next year's occurrence
        if let nextYearDate = calendar.date(from: DateComponents(year: currentYear + 1, month: month, day: day)),
           nextYearDate >= startDate && nextYearDate <= endDate {
            return nextYearDate
        }

        return nil
    }


}
