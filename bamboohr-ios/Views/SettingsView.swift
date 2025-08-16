//
//  SettingsView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AccountSettingsViewModel
    @Binding var selectedTab: Int
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingApiKeyInfo = false
    @State private var showingClearConfirmation = false
    @State private var selectedLanguage: LanguageOption = .system

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Connection status section
                    connectionStatusSection

                    // Account configuration section
                    accountConfigSection

                    // Actions section
                    actionsSection

                    // General settings section
                    generalSettingsSection

                    // App information section
                    appInfoSection
                }
                .padding(.horizontal) // 只保留水平padding
                .padding(.bottom) // 只保留底部padding
            }
            .contentMargins(.top, -15) // 移除顶部内容边距
            .onAppear {
                selectedLanguage = localizationManager.getCurrentLanguageOption()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        if let tabInfo = FloatingNavigationBar.getTabInfo(for: selectedTab) {
                            Image(systemName: tabInfo.activeIcon)
                                .foregroundColor(tabInfo.color)
                        } else {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.gray)
                        }
                        Text(localizationManager.localized(.settingsTitle))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert(localizationManager.localized(.settingsApiKeyHelp), isPresented: $showingApiKeyInfo) {
                Button(localizationManager.localized(.confirm), role: .cancel) { }
            } message: {
                Text(getLocalizedText(
                    "1. 登录BambooHR网页版\n2. 进入账户设置\n3. 导航到API密钥部分\n4. 生成新的API密钥\n\n注意：您可能需要管理员权限来生成API密钥。",
                    "1. Log in to BambooHR web\n2. Go to Account Settings\n3. Navigate to API Keys section\n4. Generate a new API key\n\nNote: You may need admin permissions to generate API keys."
                ))
            }
            .alert(localizationManager.localized(.settingsClear), isPresented: $showingClearConfirmation) {
                Button(localizationManager.localized(.cancel), role: .cancel) { }
                Button(localizationManager.localized(.settingsClear), role: .destructive) {
                    viewModel.clearSettings()
                }
            } message: {
                Text(getLocalizedText(
                    "确定要清除所有账户设置吗？此操作无法撤销。",
                    "Are you sure you want to clear all account settings? This action cannot be undone."
                ))
            }
        }
    }

    // MARK: - General Settings Section
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(localizationManager.localized(.settingsGeneralSettings))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                        .font(.title3)
                        .frame(width: 24)

                    Text(localizationManager.localized(.settingsLanguage))
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()

                    Menu {
                        ForEach(LanguageOption.allCases, id: \.self) { option in
                            Button(action: {
                                selectedLanguage = option
                                localizationManager.setLanguagePreference(option)
                            }) {
                                HStack {
                                    Text(option.displayName)
                                    if selectedLanguage == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedLanguage.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Connection Status Section
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(localizationManager.localized(.settingsConnectionStatus))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack {
                StatusBadge(
                    isConnected: viewModel.hasValidSettings,
                    connectedText: localizationManager.localized(.settingsConnected),
                    disconnectedText: localizationManager.localized(.settingsNotConfigured)
                )

                Spacer()
            }

            Text(viewModel.hasValidSettings
                 ? localizationManager.localized(.settingsConnectionNormal)
                 : localizationManager.localized(.settingsConfigureAccount))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Account Configuration Section
    private var accountConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(localizationManager.localized(.settingsBambooAccount))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 16) {
                ModernInputField(
                    title: localizationManager.localized(.settingsCompanyDomain),
                    placeholder: "mycompany",
                    text: $viewModel.companyDomain,
                    icon: "building.2"
                )

                ModernInputField(
                    title: localizationManager.localized(.settingsEmployeeId),
                    placeholder: "12345",
                    text: $viewModel.employeeId,
                    icon: "person.text.rectangle"
                )

                ModernSecureField(
                    title: localizationManager.localized(.settingsApiKey),
                    placeholder: getLocalizedText("在此输入API密钥", "Enter API key here"),
                    text: $viewModel.apiKey,
                    icon: "key"
                ) {
                    Button {
                        showingApiKeyInfo = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle")
                                .font(.caption)
                            Text(localizationManager.localized(.settingsApiKeyHelp))
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Save Settings Button
            Button(action: {
                viewModel.saveSettings()
            }) {
                HStack {
                    if viewModel.isTesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Image(systemName: "checkmark.circle")
                        .font(.headline)
                    Text(viewModel.isTesting ? localizationManager.localized(.settingsSaving) : localizationManager.localized(.settingsSave))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .primaryGradientButtonStyle(isDisabled: viewModel.isTesting || !viewModel.hasRequiredFields)
            .disabled(viewModel.isTesting || !viewModel.hasRequiredFields)

            // Clear Settings Button
            Button(action: {
                showingClearConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.headline)
                    Text(localizationManager.localized(.settingsClear))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .destructiveGradientButtonStyle(isDisabled: !viewModel.hasValidSettings)
            .disabled(!viewModel.hasValidSettings)
        }
    }

    // MARK: - App Information Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
                    .font(.title2)
                Text(localizationManager.localized(.settingsAppInfo))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 8) {
                InfoRow(
                    title: localizationManager.localized(.settingsVersion),
                    value: appVersion,
                    icon: "app.badge"
                )

                InfoRow(
                    title: localizationManager.localized(.settingsMinimumIos),
                    value: "iOS 15.0+",
                    icon: "iphone"
                )

                InfoRow(
                    title: localizationManager.localized(.settingsBuildDate),
                    value: buildDate,
                    icon: "calendar"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Helper Properties
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildDate: String {
        let formatter = DateFormatter()
        if localizationManager.currentLanguage == "zh-Hans" {
            formatter.dateFormat = "yyyy年M月d日"
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: Date())
    }

    private func getLocalizedText(_ chinese: String, _ english: String) -> String {
        return localizationManager.currentLanguage == "zh-Hans" ? chinese : english
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let isConnected: Bool
    let connectedText: String
    let disconnectedText: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(isConnected ? connectedText : disconnectedText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isConnected ? .green : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill((isConnected ? Color.green : Color.orange).opacity(0.1))
        )
    }
}

// MARK: - Modern Input Field
struct ModernInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
}

// MARK: - Modern Secure Field
struct ModernSecureField<Content: View>: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    let accessory: () -> Content

    init(title: String, placeholder: String, text: Binding<String>, icon: String, @ViewBuilder accessory: @escaping () -> Content = { EmptyView() }) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.accessory = accessory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                accessory()
            }

            SecureField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .font(.title3)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView(viewModel: AccountSettingsViewModel(bambooHRService: BambooHRService.shared), selectedTab: .constant(4))
}
