# BambooHR iOS App

A modern iOS application that integrates with the BambooHR API, providing employees with convenient human resource management features.

English | [中文](README.md)

## 🌟 Features

- 🏠 **Smart Dashboard**: Display personal information, work statistics, and today's overview
- ⏰ **My Time**: Convenient work time recording with project and task classification
- 🏖️ **Who's Out**: Real-time view of team member leave schedules with avatar display
- ⚙️ **Settings Management**: Secure account configuration and connection testing
- 🌍 **Multi-language Support**: Automatic switching between Chinese and English based on system language settings
- 🔔 **Smart Notifications**: Elegant Toast message notification system
- 📊 **Data Statistics**: Work hours and leave statistics based on real data

## 🆕 Latest Updates

### v2.0 New Features
- ✨ **Multi-language Support**: Automatic language detection supporting Chinese and English
- 🎯 **Toast Notification System**: Replace traditional popups with elegant message feedback
- 👤 **User Avatar Display**: Real user avatars displayed on Who's Out page
- 🎨 **Interface Optimization**: Full-width project selection for better user experience
- 📈 **Real Data**: Dashboard statistics based on actual work data calculations
- 🔄 **Real-time Loading**: Automatic loading of corresponding time records when switching dates

## Project Architecture

### Application Structure
```
bamboohr-ios/
├── bamboohr_iosApp.swift      # Main application entry
├── ContentView.swift          # Default content view (unused)
├── Item.swift                 # Sample data model (unused)
├── Models/                    # Data model layer
│   ├── User.swift             # User information model
│   ├── TimeEntry.swift        # Time record model
│   ├── BambooLeaveInfo.swift  # Leave information model
│   ├── TimeOffBalance.swift   # Leave balance model
│   └── AccountSettings.swift  # Account settings model
├── Services/                  # Network service layer
│   └── BambooHRService.swift  # BambooHR API service
├── ViewModels/                # View model layer (MVVM architecture)
│   ├── UserViewModel.swift    # User data management
│   ├── TimeEntryViewModel.swift # My Time management
│   ├── LeaveViewModel.swift   # Leave data management
│   └── AccountSettingsViewModel.swift # Settings management
├── Views/                     # User interface layer
│   ├── MainTabView.swift      # Main navigation
│   ├── HomeView.swift         # Dashboard view
│   ├── TimeEntryView.swift    # My Time interface
│   ├── LeaveView.swift        # Leave management interface
│   └── SettingsView.swift     # Settings interface
└── Utilities/                 # Utility classes
    ├── KeychainManager.swift  # Keychain management
    ├── ToastManager.swift     # Toast notification system
    └── LocalizationManager.swift # Multi-language management
```

## Core Features Overview

### 🌍 **Multi-language Support**

#### Automatic Language Detection
- Automatic switching between Chinese and English based on system language
- Support for runtime language switching
- Complete UI localization

#### LocalizationManager (`Utilities/LocalizationManager.swift`)
```swift
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    @Published var currentLanguage: String

    func localized(_ key: LocalizationKey) -> String
    func setLanguage(_ language: String)
}
```

### 🔔 **Toast Notification System**

#### Smart Message Feedback
- Four types: success, error, info, warning
- Auto-dismiss mechanism
- Elegant animation effects
- Non-intrusive design

#### ToastManager (`Utilities/ToastManager.swift`)
```swift
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var toasts: [ToastData] = []

    func success(_ message: String)
    func error(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
}
```

### 📊 **Data Model Layer (`Models/`)**

#### User Model (`User.swift`)
```swift
@Model class User {
    var id: String
    var firstName: String
    var lastName: String
    var jobTitle: String
    var department: String
    var photoUrl: String?
    var nickname: String?

    var fullName: String { "\(firstName) \(lastName)" }
}
```

#### My Time Model (`TimeEntry.swift`)
```swift
@Model class TimeEntry {
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
}
```

#### Leave Information (`BambooLeaveInfo.swift`)
```swift
struct BambooLeaveInfo {
    let id: Int
    let type: String
    let employeeId: Int?
    let name: String
    let start: String
    let end: String
    var photoUrl: String?

    var startDate: Date? { /* Date parsing */ }
    var endDate: Date? { /* Date parsing */ }
    var leaveDuration: Int? { /* Leave days calculation */ }
}
```

### 🌐 **Network Service Layer (`Services/`)**

#### BambooHR Service (`BambooHRService.swift`)
- **Singleton Pattern**: `BambooHRService.shared`
- **Authentication**: Basic Auth with API Key
- **Multi-format Support**: XML user data + JSON other data
- **Error Handling**: Complete error type definitions

```swift
class BambooHRService {
    static let shared = BambooHRService()

    func fetchCurrentUser() -> AnyPublisher<User, BambooHRError>
    func fetchTimeEntries(for date: Date) -> AnyPublisher<[TimeEntry], BambooHRError>
    func fetchTimeOffEntries(startDate: Date, endDate: Date) -> AnyPublisher<[BambooLeaveInfo], BambooHRError>
    func fetchProjects() -> AnyPublisher<[Project], BambooHRError>
    func submitTimeEntry(_ timeEntry: TimeEntry) -> AnyPublisher<Bool, BambooHRError>
    func updateAccountSettings(_ settings: AccountSettings)
}
```

### 🎨 **View Model Layer (`ViewModels/`)**

#### My Time View Model (`TimeEntryViewModel.swift`)
- **Auto-loading**: Automatically load projects and time records on initialization
- **Date Listening**: Automatically refresh records when switching dates
- **Form Validation**: Smart project and task validation
- **Toast Integration**: Multi-language error and success notifications

```swift
class TimeEntryViewModel: ObservableObject {
    @Published var selectedDate = Date() {
        didSet {
            if selectedDate != oldValue {
                loadTimeEntries()
            }
        }
    }

    var totalHoursForDate: Double { /* Calculate daily total hours */ }
    var formattedTotalHours: String { /* Formatted display */ }
}
```

### 📱 **User Interface Layer (`Views/`)**

#### Dashboard View (`HomeView.swift`)
- **Smart Statistics**: Work hours statistics based on real data
- **User Information**: Avatar loading and personal information display
- **Today's Overview**: Current work status and Who's Out status
- **Multi-language**: Complete Chinese and English interface

#### My Time View (`TimeEntryView.swift`)
- **Full-width Selector**: Project selection occupies full screen width
- **Cascading Selection**: Smart Project→Task cascading
- **Record Display**: Time record list for current date
- **Real-time Calculation**: Automatic calculation and display of total hours

#### Leave View (`LeaveView.swift`)
- **User Avatars**: 36x36 circular avatar display
- **Leave Types**: Iconized leave type display
- **Date Information**: Leave start date and duration
- **Statistics Overview**: Today, tomorrow, and weekly leave statistics

#### Settings View (`SettingsView.swift`)
- **Connection Status**: Real-time connection status display
- **Secure Input**: Password field and help information
- **Connection Test**: One-click API connection testing
- **Data Cleanup**: Secure settings clearing functionality

### 🔐 **Utility Classes (`Utilities/`)**

#### Keychain Manager (`KeychainManager.swift`)
```swift
class KeychainManager {
    static let shared = KeychainManager()

    func saveAccountSettings(_ settings: AccountSettings) throws
    func loadAccountSettings() -> AccountSettings?
    func clearAccountSettings() throws

    private func save(key: String, data: Data) throws
    private func load(key: String) -> Data?
    private func delete(key: String) throws
}
```

## Technology Stack

### 🛠️ Development Frameworks
- **SwiftUI**: Declarative UI framework
- **SwiftData**: Local data persistence
- **Combine**: Reactive programming

### 🌐 Network & Data
- **URLSession**: HTTP network requests
- **AsyncImage**: Asynchronous image loading
- **JSONDecoder/XMLParser**: Multi-format data parsing
- **Keychain Services**: Secure credential storage

### 🏗️ Architecture Patterns
- **MVVM**: Model-View-ViewModel
- **Singleton**: Service layer singleton pattern
- **Publisher-Subscriber**: Reactive data flow
- **Dependency Injection**: Dependency injection

## API Integration

### BambooHR REST API
- **Authentication**: API Key + Basic Auth
- **Data Formats**: JSON (primary) / XML (user data)
- **Error Handling**: Complete error type system

### Supported Endpoints
```
GET /v1/employees/{id}           # Get employee info (XML)
GET /v1/time_off/requests        # Get leave requests (JSON)
GET /v1/time_tracking/projects   # Get project list (JSON)
GET /v1/time_tracking/hour_entries/{date} # Get time records (JSON)
POST /v1/time_tracking/hour_entries      # Submit time record (JSON)
```

### Network Error Handling
```swift
enum BambooHRError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case authenticationError
    case networkError(Error)
    case decodingError(Error)
    case unknownError(String)

    var errorDescription: String? { /* Localized error description */ }
}
```

## Security Features

### 🔒 Data Security
- **Keychain Storage**: API key encrypted storage
- **HTTPS Enforcement**: All API requests use HTTPS
- **Authentication Verification**: Real-time connection testing
- **Data Isolation**: Local cache and remote data separation

### 🛡️ Privacy Protection
- **Minimum Permissions**: Only request necessary user data
- **Local First**: Sensitive data prioritizes local storage
- **Auto Cleanup**: Automatic cache clearing on logout

## User Experience

### 🎨 Interface Design
- **Material Design 3**: Modern design language
- **Dark Mode**: Automatic system theme adaptation
- **Responsive Layout**: Adapts to various device sizes
- **Smooth Animations**: 60fps smooth interactions

### 📱 Interaction Optimization
- **Pull to Refresh**: Gesture-driven data updates
- **Toast Notifications**: Non-intrusive message prompts
- **Smart Loading**: Pagination and lazy loading optimization
- **Error Retry**: Automatic retry for network exceptions

### 🔄 Data Synchronization
- **Incremental Updates**: Smart data differential synchronization
- **Offline Support**: Local data access without network
- **Conflict Resolution**: Automatic data conflict handling

## Development Requirements

### 📋 System Requirements
- **Minimum Version**: iOS 18.2+
- **Development Tools**: Xcode 15.0+
- **Language Version**: Swift 5.9+
- **Architecture Support**: arm64, x86_64

### 🔧 Dependency Management
- **Swift Package Manager**: Dependency package management
- **Built-in Frameworks**: No third-party dependencies
- **Modular Design**: Loosely coupled component architecture

## Configuration Guide

### 🚀 First Time Setup
1. **Get API Key**
   - Login to BambooHR web version
   - Navigate to API settings page
   - Generate new API key

2. **Configure Application**
   - Open application settings page
   - Enter company domain (e.g., mycompany)
   - Fill in employee ID and API key
   - Click test connection to verify

3. **Start Using**
   - Automatically navigate to dashboard after successful connection
   - View personal information and work statistics
   - Start recording work time

### ⚙️ Advanced Configuration
- **Language Settings**: Follow system language or manual switching
- **Notification Preferences**: Customize Toast display duration
- **Data Sync**: Configure automatic sync frequency
- **Privacy Settings**: Manage local data storage

### 🔍 Troubleshooting
- **Connection Failed**: Check network and API key
- **Data Not Updating**: Pull to refresh or re-login
- **Interface Issues**: Restart app or clear cache

## Development Contribution

### 🛠️ Development Environment Setup
```bash
# Clone project
git clone https://github.com/your-repo/bamboohr-ios.git

# Open project
cd bamboohr-ios
open bamboohr-ios.xcodeproj
```

### 📝 Code Standards
- **Swift Style Guide**: Follow official coding style
- **MVVM Architecture**: Strict architectural layering
- **Unit Testing**: Core logic test coverage
- **Documentation Comments**: Complete API documentation

### 🎯 Contribution Process
1. Fork project repository
2. Create feature branch
3. Submit code changes
4. Create Pull Request
5. Code review and merge

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support & Feedback

- **Bug Reports**: [GitHub Issues](https://github.com/your-repo/bamboohr-ios/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/your-repo/bamboohr-ios/discussions)
- **Technical Support**: support@yourcompany.com

---

*Last updated: December 2024*