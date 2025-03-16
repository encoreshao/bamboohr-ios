//
//  SettingsView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AccountSettingsViewModel
    @State private var showingApiKeyInfo = false
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("BambooHR Account")) {
                    TextField("Company Domain", text: $viewModel.companyDomain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)

                    TextField("Employee ID", text: $viewModel.employeeId)
                        .keyboardType(.numberPad)

                    SecureField("API Key", text: $viewModel.apiKey)

                    Button(action: {
                        showingApiKeyInfo = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("How to get your API Key")
                        }
                    }
                    .foregroundColor(.blue)
                }

                Section {
                    Button(action: {
                        viewModel.saveSettings()
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                                    .padding(.trailing, 10)
                            }
                            Text("Save Settings")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isSaving)

                    if viewModel.isConfigured {
                        Button(action: {
                            showingClearConfirmation = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Clear Settings")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }

                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                if let successMessage = viewModel.successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Minimum iOS")
                        Spacer()
                        Text("iOS 15.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        // Image("40")
                        //     .resizable()
                        //     .scaledToFit()
                        //     .frame(height: 30)
                        Text("Settings")
                            .font(.headline)
                    }
                }
            }
            .alert("How to Get Your API Key", isPresented: $showingApiKeyInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("1. Log in to BambooHR web version\n2. Go to your account settings\n3. Navigate to API Keys section\n4. Generate a new API Key\n\nNote: You may need administrator permissions to generate an API key.")
            }
            .alert("Clear Settings", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    viewModel.clearSettings()
                }
            } message: {
                Text("Are you sure you want to clear all your account settings? This action cannot be undone.")
            }
        }
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = AccountSettingsViewModel(bambooHRService: service)
    return SettingsView(viewModel: viewModel)
}
