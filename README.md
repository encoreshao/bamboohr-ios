# BambooHR iOS App

## Project Overview

The BambooHR iOS app is a mobile client for interacting with the BambooHR human resource management system. The app allows users to view personal information, see who's on leave today, record work hours, and submit them to the BambooHR system.

## Features

- **User Profile**: Display basic information of the currently logged-in user, including avatar, name, job title, and department
- **Leave Information**: View who's on leave today and tomorrow, including leave type, dates, and count
- **Time Tracking**: Record work hours, select projects and tasks, add , and submit to BambooHR
- **Account Settings**: Configure BambooHR account information, including company domain, employee ID, and personal access token
- **Debug Logging**: Detailed debug logs to help diagnose API integration issues

## Technology Stack

- Swift 5.5+
- SwiftUI
- Combine Framework
- SwiftData
- iOS 15.0+
- MVVM Architecture Pattern

## Technical Implementation

- **XML Parsing**: Using XMLParser and custom XMLParserDelegate to parse XML format user data returned by the BambooHR API
- **URL Handling**: Using URLComponents to correctly build API request URLs, ensuring query parameters are properly encoded
- **SwiftData Integration**: Ensuring model classes are compatible with SwiftData by moving Codable implementation to extensions
- **Task Selection**: Implementing two-level selection for projects and tasks, improving the accuracy of time entries
- **Debug Logging**: Detailed logging system recording API requests, responses, and error information for troubleshooting

## Project Structure

```
bamboohr-ios/
├── Models/              # Data models
│   ├── User.swift       # User information model
│   ├── LeaveInfo.swift  # Leave information model
│   ├── TimeEntry.swift  # Time entry model (including projects and tasks)
│   └── AccountSettings.swift # Account settings model
├── ViewModels/          # View models
│   ├── UserViewModel.swift
│   ├── LeaveViewModel.swift
│   ├── TimeEntryViewModel.swift
│   └── AccountSettingsViewModel.swift
├── Views/               # User interface
│   ├── MainTabView.swift # Main tab view
│   ├── HomeView.swift   # Home view
│   ├── LeaveView.swift  # Leave information view
│   ├── TimeEntryView.swift # Time entry view
│   └── SettingsView.swift # Settings view
├── Services/            # Services
│   └── BambooHRService.swift # BambooHR API service (supporting XML and JSON parsing)
└── Utilities/           # Utilities
    └── KeychainManager.swift # Secure storage manager
```

## Installation Requirements

- iOS 15.0 or higher
- Xcode 13.0 or higher
- Valid BambooHR account and API access

## Installing on a Physical Device

To install this app on your iPhone or iPad, you need:

1. **Apple Developer Account**:

   - Free account: Can install on a limited number of devices, but the app will expire after 7 days
   - Paid account (Apple Developer Program, $99 per year): Can install on more devices, app valid for 1 year

2. **Device Registration**:

   - Connect your iPhone/iPad to your Mac
   - Open the project in Xcode
   - Select "Devices and Simulators" from the "Window" menu in Xcode
   - Confirm your device is listed and trusted

3. **Signing Configuration**:

   - Select the project in the project navigator in Xcode
   - Select the "Signing & Capabilities" tab
   - Select your development team (using your Apple ID)
   - If errors appear, click "Try Again" or manually fix signing issues

4. **Build and Run**:

   - Select your device in the device selector at the top of Xcode
   - Click the run button (▶️) or use the shortcut Cmd+R
   - When installing for the first time, you may need to trust the developer certificate on your device:
     - On your iPhone/iPad, go to Settings > General > VPN & Device Management
     - Find your Apple ID or developer account
     - Tap "Trust"

5. **Common Issues**:
   - **"Unable to Install App" Error**: Usually due to signing issues or device restrictions. Make sure your Apple ID is added to the project and your device is registered in your account.
   - **App Installs but Crashes Immediately**: Check if the app's minimum iOS version requirement is compatible with your device.
   - **"Untrusted Developer" Warning**: Follow the instructions in step 4 above to trust the developer certificate.

## Usage Instructions

### First-time Setup

1. Download and install the app
2. Open the app, it will automatically navigate to the "Settings" tab
3. Enter the following information:
   - **Company Domain**: Your BambooHR company subdomain (e.g., if your BambooHR URL is `https://company.bamboohr.com`, enter `company`)
   - **Employee ID**: Your employee ID in the BambooHR system
   - **API Key**: Your BambooHR personal access token (can be generated in BambooHR account settings)
4. Click the "Save Settings" button

### Viewing User Information

- Navigate to the "Home" tab
- The app will display your personal information, including avatar, name, job title, and department

### Viewing Leave Information

- Navigate to the "Leave" tab
- The app will display:
  - A list of employees on leave today with a count
  - A list of employees on leave tomorrow with a count
- If no one is on leave for a particular day, it will show a message indicating this
- Click the refresh button in the top right corner to manually refresh the data

### Recording Work Time

1. Navigate to the "Time" tab
2. Select a date
3. Use the slider or stepper to input work hours
4. Select a project from the list
5. Select a task from the list (if the project has associated tasks)
6. Add note (optional)
7. Click the "Submit Time Entry" button

## Security

- All API credentials are securely stored using iOS Keychain
- The app only accesses the BambooHR API when needed
- Sensitive employee data is not permanently stored on the device

## Getting BambooHR API Access

To use this app, you need:

1. A valid BambooHR account
2. BambooHR API access (usually requires administrator authorization)
3. Generate a personal access token:
   - Log in to the BambooHR web version
   - Go to account settings
   - Navigate to the API Keys section
   - Generate a new API key

## Troubleshooting

If you encounter issues:

- **Cannot Log In**: Make sure your company domain, employee ID, and API key are correct
- **Cannot Load Data**: Check your network connection and ensure your API key has sufficient permissions
- **Cannot Submit Time**: Make sure you've selected valid projects and tasks (if required) and that you have permission to submit time
- **XML Parsing Error**: Check if the XML format returned by the BambooHR API matches expectations, view debug logs for details
- **View Debug Logs**: The app outputs detailed debug logs to the console, including API requests, responses, and error information, which can help diagnose issues
