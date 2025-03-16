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
                photoUrl: photoUrl
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
    private var accountSettings: AccountSettings?
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(accountSettings: AccountSettings? = nil) {
        self.accountSettings = accountSettings
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
            URLQueryItem(name: "fields", value: "firstName,lastName,jobTitle,department,location")
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
                        return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                    }
                }

                // Parse XML response
                do {
                    let user = try self.parseUserXML(data: data)
                    return Just(user)
                        .setFailureType(to: BambooHRError.self)
                        .eraseToAnyPublisher()
                } catch {
                    print("DEBUG: XML parsing error: \(error.localizedDescription)")
                    return Fail(error: BambooHRError.decodingError(error)).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchTimeOffEntries(startDate: Date, endDate: Date) -> AnyPublisher<[LeaveInfo], BambooHRError> {
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
            .flatMap { data, response -> AnyPublisher<[LeaveInfo], BambooHRError> in
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
                            print("DEBUG: Leave response body: \(responseString)")
                        }
                        return Fail(error: BambooHRError.unknownError("Status code: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                    }
                }

                return Just(data)
                    .decode(type: [LeaveInfo].self, decoder: self.decoder)
                    .mapError { error -> BambooHRError in
                        print("DEBUG: Decoding error in leave response: \(error.localizedDescription)")
                        return BambooHRError.decodingError(error)
                    }
                    .eraseToAnyPublisher()
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
}
