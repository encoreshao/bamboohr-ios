//
//  LocalizationManager.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import Foundation
import SwiftUI

// MARK: - Localization Keys
enum LocalizationKey: String, CaseIterable {
    // Tab titles
    case tabHome = "tab_home"
    case tabTime = "tab_time"
    case tabLeave = "tab_leave"
    case tabSettings = "tab_settings"

    // Home screen
    case homeTitle = "home_title"
    case homeGreetingMorning = "home_greeting_morning"
    case homeGreetingAfternoon = "home_greeting_afternoon"
    case homeGreetingEvening = "home_greeting_evening"
    case homeGreetingNight = "home_greeting_night"
    case homeGreetingSubtitle = "home_greeting_subtitle"
    case homeWeeklyHours = "home_weekly_hours"
    case homeRemainingLeave = "home_remaining_leave"
    case homeActiveProjects = "home_active_projects"
    case homeTeamSize = "home_team_size"
    case homeTodayTitle = "home_today_title"
    case homeTodayNoLeave = "home_today_no_leave"
    case homeTodayOnePersonOff = "home_today_one_person_off"
    case homeTodayMultiplePeopleOff = "home_today_multiple_people_off"
    case homeHours = "home_hours"
    case homeQuickStats = "home_quick_stats"
    case homeTodayOverview = "home_today_overview"
    case homeStillNeed = "home_still_need"
    case homeWeeklyWork = "home_weekly_work"
    case homeWorkStatus = "home_work_status"
    case homeWorkStatusActive = "home_work_status_active"
    case homeWorkStatusStarted = "home_work_status_started"
    case homeLeaveBalance = "home_leave_balance"
    case homeOnLeave = "home_on_leave"
    case homePeople = "home_people"
    case homeViewDetails = "home_view_details"
    case homeMonthlyProjects = "home_monthly_projects"
    case homeInProgress = "home_in_progress"
    case homeTodayTasks = "home_today_tasks"
    case homeTasksCompleted = "home_tasks_completed"
    case homeDepartmentMembers = "home_department_members"

    // Time Entry screen
    case timeTitle = "time_title"
    case timeDateLabel = "time_date_label"
    case timeHoursLabel = "time_hours_label"
    case timeProjectLabel = "time_project_label"
    case timeTaskLabel = "time_task_label"
    case timeNotesLabel = "time_notes_label"
    case timeSelectProject = "time_select_project"
    case timeSelectTask = "time_select_task"
    case timeSubmitButton = "time_submit_button"
    case timeSubmittedMessage = "time_submitted_message"
    case timeRecordsLoaded = "time_entries_loaded"
    case timeToday = "time_today"
    case timeRecordsFor = "time_records_for"
    case timeProject = "time_project"
    case timeRecordsTitle = "time_records_title"
    case timeNoRecords = "time_no_records"
    case timeTotalHours = "time_total_hours"
    case timeTodayRecords = "time_today_records"
    case timeSelectDate = "time_select_date"
    case timeWorkDuration = "time_work_duration"
    case timeDuration = "time_duration"
    case timeProjectSelection = "time_project_selection"
    case timeNoProjects = "time_no_projects"
    case timeNotes = "time_notes"
    case timeSubmit = "time_submit"
    case timeSubmitting = "time_submitting"
    case timeSubmitted = "time_submitted"

    // Leave screen
    case leaveTitle = "leave_title"
    case leaveTodayTitle = "leave_today_title"
    case leaveTomorrowTitle = "leave_tomorrow_title"
    case leaveWeekTitle = "leave_week_title"
    case leaveTodayBadge = "leave_today_badge"
    case leaveNoEntries = "leave_no_entries"
    case leaveInfoUpdated = "leave_info_updated"
    case leaveTomorrow = "leave_tomorrow"
    case leaveWeekly = "leave_weekly"
    case leaveViewDetails = "leave_view_details"
    case leaveToday = "leave_today"
    case loadingLeaveInfo = "loading_leave_info"
    case leaveWeeklyOverview = "leave_weekly_overview"
    case leaveAllPresent = "leave_all_present"

    // Settings screen
    case settingsTitle = "settings_title"
    case settingsConnectionStatus = "settings_connection_status"
    case settingsConnected = "settings_connected"
    case settingsDisconnected = "settings_disconnected"
    case settingsNotConfigured = "settings_not_configured"
    case settingsAccountConfig = "settings_account_config"
    case settingsBambooAccount = "settings_bamboo_account"
    case settingsCompanyDomain = "settings_company_domain"
    case settingsEmployeeId = "settings_employee_id"
    case settingsApiKey = "settings_api_key"
    case settingsActions = "settings_actions"
    case settingsSave = "settings_save"
    case settingsSaving = "settings_saving"
    case settingsClear = "settings_clear"
    case settingsAppInfo = "settings_app_info"
    case settingsVersion = "settings_version"
    case settingsBuildDate = "settings_build_date"
    case settingsMinimumIos = "settings_minimum_ios"
    case settingsClearConfirmation = "settings_clear_confirmation"
    case settingsApiKeyInfo = "settings_api_key_info"
    case settingsApiKeyHelp = "settings_api_key_help"
    case settingsConnectionNormal = "settings_connection_normal"
    case settingsConfigureAccount = "settings_configure_account"
    case confirm = "confirm"
    case settingsSaved = "settings_saved"
    case settingsCleared = "settings_cleared"

    // Language settings
    case settingsLanguage = "settings_language"
    case settingsLanguageAuto = "settings_language_auto"
    case settingsLanguageEnglish = "settings_language_english"
    case settingsLanguageChinese = "settings_language_chinese"
    case settingsGeneralSettings = "settings_general_settings"

    // Common messages
    case loading = "loading"
    case error = "error"
    case success = "success"
    case cancel = "cancel"
    case ok = "ok"
    case retry = "retry"
    case refreshData = "refresh_data"
    case refresh = "refresh"
    case noData = "no_data"
    case loadingFailed = "loading_failed"
    case networkError = "network_error"
    case authenticationError = "authentication_error"
    case connectionTestFailed = "connection_test_failed"
    case allFieldsRequired = "all_fields_required"
    case loadingUserInfo = "loading_user_info"
    case projectsLoaded = "projects_loaded"
    case projectsLoadFailed = "projects_load_failed"
    case userInfoUnavailable = "user_info_unavailable"
    case checkSettings = "check_settings"
}

// MARK: - Language Settings
enum LanguageOption: String, CaseIterable {
    case system = "system"
    case english = "en"
    case chinese = "zh-Hans"

    var displayName: String {
        switch self {
        case .system:
            return LocalizationManager.shared.localized(.settingsLanguageAuto)
        case .english:
            return LocalizationManager.shared.localized(.settingsLanguageEnglish)
        case .chinese:
            return LocalizationManager.shared.localized(.settingsLanguageChinese)
        }
    }
}

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String

    private let supportedLanguages = ["en", "zh-Hans"]
    private var localizations: [String: [String: String]] = [:]
    private let languageKey = "user_preferred_language"

    private init() {
        // Load user preference first
        let userPreference = UserDefaults.standard.string(forKey: languageKey)

        if let userPreference = userPreference, userPreference != "system" {
            // User has set a specific language preference
            currentLanguage = userPreference
        } else {
            // Use system language or auto-detect
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            if systemLanguage.hasPrefix("zh") {
                currentLanguage = "zh-Hans"
            } else {
                currentLanguage = "en"
            }
        }

        loadLocalizations()
    }

    func setLanguagePreference(_ option: LanguageOption) {
        switch option {
        case .system:
            UserDefaults.standard.set("system", forKey: languageKey)
            // Auto-detect system language
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            if systemLanguage.hasPrefix("zh") {
                currentLanguage = "zh-Hans"
            } else {
                currentLanguage = "en"
            }
        case .english:
            UserDefaults.standard.set("en", forKey: languageKey)
            currentLanguage = "en"
        case .chinese:
            UserDefaults.standard.set("zh-Hans", forKey: languageKey)
            currentLanguage = "zh-Hans"
        }

        UserDefaults.standard.synchronize()
    }

    func getCurrentLanguageOption() -> LanguageOption {
        let userPreference = UserDefaults.standard.string(forKey: languageKey)

        if let userPreference = userPreference {
            switch userPreference {
            case "system":
                return .system
            case "en":
                return .english
            case "zh-Hans":
                return .chinese
            default:
                return .system
            }
        } else {
            return .system
        }
    }

    private func loadLocalizations() {
        localizations = [
            "en": [
                // Tab titles
                "tab_home": "Home",
                "tab_time": "Time",
                "tab_leave": "Leave",
                "tab_settings": "Settings",

                // Home screen
                "home_title": "Dashboard",
                "home_greeting_morning": "Good morning",
                "home_greeting_afternoon": "Good afternoon",
                "home_greeting_evening": "Good evening",
                "home_greeting_night": "Good night",
                "home_greeting_subtitle": "Your daily overview",
                "home_weekly_hours": "Weekly Hours",
                "home_remaining_leave": "Leave Balance",
                "home_active_projects": "Active Projects",
                "home_team_size": "Team Size",
                "home_today_title": "Today's Status",
                "home_today_no_leave": "Everyone is working today",
                "home_today_one_person_off": "1 person is on leave",
                "home_today_multiple_people_off": "%d people are on leave",
                "home_hours": "Hours",
                "home_quick_stats": "Quick Stats",
                "home_today_overview": "Today's Overview",
                "home_still_need": "Still need to do",
                "home_weekly_work": "Weekly Work",
                "home_work_status": "Work Status",
                "home_work_status_active": "Active",
                "home_work_status_started": "Started",
                "home_leave_balance": "Leave Balance",
                "home_on_leave": "On Leave",
                "home_people": "People",
                "home_view_details": "View Details",
                "home_monthly_projects": "Monthly Projects",
                "home_in_progress": "In Progress",
                "home_today_tasks": "Today's Tasks",
                "home_tasks_completed": "Tasks Completed",
                "home_department_members": "Department Members",

                // Time Entry screen
                "time_title": "Time Entry",
                "time_date_label": "Date",
                "time_hours_label": "Hours",
                "time_project_label": "Project",
                "time_task_label": "Task",
                "time_notes_label": "Notes",
                "time_select_project": "Select Project",
                "time_select_task": "Select Task",
                "time_submit_button": "Submit",
                "time_records_title": "Today's Records",
                "time_no_records": "No time records for this date",
                "time_total_hours": "Total Hours",
                "time_today_records": "Today's Records",
                "time_select_date": "Select Date",
                "time_work_duration": "Work Duration",
                "time_duration": "Duration",
                "time_project_selection": "Project Selection",
                "time_no_projects": "No projects available",
                "time_notes": "Notes",
                "time_submit": "Submit",
                "time_submitting": "Submitting...",
                "time_submitted": "Submitted",
                "time_submitted_message": "Time entry submitted successfully",
                "time_entries_loaded": "Time records loaded",
                "time_today": "Today",
                "time_records_for": "Records for",
                "time_project": "Project",

                // Leave screen
                "leave_title": "Team Leave",
                "leave_today_title": "Today",
                "leave_tomorrow_title": "Tomorrow",
                "leave_week_title": "This Week",
                "leave_today_badge": "Today",
                "leave_no_entries": "No one is on leave",
                "leave_info_updated": "Leave information updated",
                "leave_tomorrow": "Tomorrow",
                "leave_weekly": "This Week",
                "leave_view_details": "View Details",
                "leave_today": "Today",
                "loading_leave_info": "Loading leave information...",
                "leave_weekly_overview": "Weekly Overview",
                "leave_all_present": "All present",

                // Settings screen
                "settings_title": "Settings",
                "settings_connection_status": "Connection Status",
                "settings_connected": "Connected",
                "settings_disconnected": "Not Connected",
                "settings_not_configured": "Settings not configured",
                "settings_account_config": "Account Configuration",
                "settings_bamboo_account": "BambooHR Account",
                "settings_company_domain": "Company Domain",
                "settings_employee_id": "Employee ID",
                "settings_api_key": "API Key",
                "settings_actions": "Actions",
                "settings_save": "Save Settings",
                "settings_saving": "Saving...",
                "settings_clear": "Clear Settings",
                "settings_app_info": "App Information",
                "settings_version": "Version",
                "settings_build_date": "Build Date",
                "settings_minimum_ios": "Minimum iOS",
                "settings_clear_confirmation": "Are you sure you want to clear all settings?",
                "settings_api_key_info": "Your BambooHR API key for authentication",
                "settings_api_key_help": "Help with API key",
                "settings_connection_normal": "Connection Normal",
                "settings_configure_account": "Configure Account",
                "confirm": "OK",
                "settings_saved": "Settings saved successfully",
                "settings_cleared": "Settings cleared successfully",

                // Language settings
                "settings_language": "Language",
                "settings_language_auto": "Follow System",
                "settings_language_english": "English",
                "settings_language_chinese": "简体中文",
                "settings_general_settings": "General Settings",

                // Common messages
                "loading": "Loading...",
                "error": "Error",
                "success": "Success",
                "cancel": "Cancel",
                "ok": "OK",
                "retry": "Retry",
                "refresh_data": "Refresh Data",
                "refresh": "Refresh",
                "no_data": "No data available",
                "loading_failed": "Loading failed",
                "network_error": "Network connection error",
                "authentication_error": "Authentication failed. Please check your credentials.",
                "connection_test_failed": "Connection test failed",
                "all_fields_required": "All fields are required",
                "loading_user_info": "User information loaded",
                "projects_loaded": "Projects loaded successfully",
                "projects_load_failed": "Failed to load projects",
                "user_info_unavailable": "User information unavailable",
                "check_settings": "Please check your settings"
            ],
            "zh-Hans": [
                // Tab titles
                "tab_home": "主页",
                "tab_time": "时间",
                "tab_leave": "休假",
                "tab_settings": "设置",

                // Home screen
                "home_title": "主页",
                "home_greeting_morning": "早上好",
                "home_greeting_afternoon": "下午好",
                "home_greeting_evening": "晚上好",
                "home_greeting_night": "晚安",
                "home_greeting_subtitle": "您的每日概览",
                "home_weekly_hours": "本周工时",
                "home_remaining_leave": "剩余假期",
                "home_active_projects": "活跃项目",
                "home_team_size": "团队人数",
                "home_today_title": "今日状态",
                "home_today_no_leave": "今天大家都在工作",
                "home_today_one_person_off": "1人休假",
                "home_today_multiple_people_off": "%d人休假",
                "home_hours": "小时",
                "home_quick_stats": "快速统计",
                "home_today_overview": "今日概览",
                "home_still_need": "还需完成",
                "home_weekly_work": "本周工时",
                "home_work_status": "工作状态",
                "home_work_status_active": "活跃",
                "home_work_status_started": "已开始",
                "home_leave_balance": "剩余假期",
                "home_on_leave": "休假中",
                "home_people": "人数",
                "home_view_details": "查看详情",
                "home_monthly_projects": "月度项目",
                "home_in_progress": "进行中",
                "home_today_tasks": "今日任务",
                "home_tasks_completed": "任务完成",
                "home_department_members": "部门成员",

                // Time Entry screen
                "time_title": "时间录入",
                "time_date_label": "日期",
                "time_hours_label": "小时",
                "time_project_label": "项目",
                "time_task_label": "任务",
                "time_notes_label": "备注",
                "time_select_project": "选择项目",
                "time_select_task": "选择任务",
                "time_submit_button": "提交",
                "time_records_title": "今日记录",
                "time_no_records": "该日期无时间记录",
                "time_total_hours": "总计小时",
                "time_today_records": "今日记录",
                "time_select_date": "选择日期",
                "time_work_duration": "工作时长",
                "time_duration": "时长",
                "time_project_selection": "项目选择",
                "time_no_projects": "无可用项目",
                "time_notes": "备注",
                "time_submit": "提交",
                "time_submitting": "提交中...",
                "time_submitted": "已提交",
                "time_submitted_message": "时间记录提交成功",
                "time_entries_loaded": "记录加载成功",
                "time_today": "今天",
                "time_records_for": "记录于",
                "time_project": "项目",

                // Leave screen
                "leave_title": "团队休假",
                "leave_today_title": "今天",
                "leave_tomorrow_title": "明天",
                "leave_week_title": "本周",
                "leave_today_badge": "今天",
                "leave_no_entries": "无人休假",
                "leave_info_updated": "休假信息已更新",
                "leave_tomorrow": "明天",
                "leave_weekly": "本周",
                "leave_view_details": "查看详情",
                "leave_today": "今天",
                "loading_leave_info": "加载休假信息中...",
                "leave_weekly_overview": "本周概览",
                "leave_all_present": "全员到齐",

                // Settings screen
                "settings_title": "设置",
                "settings_connection_status": "连接状态",
                "settings_connected": "已连接",
                "settings_disconnected": "未连接",
                "settings_not_configured": "设置未配置",
                "settings_account_config": "账户配置",
                "settings_bamboo_account": "BambooHR账户",
                "settings_company_domain": "公司域名",
                "settings_employee_id": "员工ID",
                "settings_api_key": "API密钥",
                "settings_actions": "操作",
                "settings_save": "保存设置",
                "settings_saving": "保存中...",
                "settings_clear": "清除设置",
                "settings_app_info": "应用信息",
                "settings_version": "版本",
                "settings_build_date": "构建日期",
                "settings_minimum_ios": "最低iOS版本",
                "settings_clear_confirmation": "确定要清除所有设置吗？",
                "settings_api_key_info": "用于身份验证的BambooHR API密钥",
                "settings_api_key_help": "API密钥帮助",
                "settings_connection_normal": "连接正常",
                "settings_configure_account": "配置账户",
                "confirm": "确定",
                "settings_saved": "设置保存成功",
                "settings_cleared": "设置清除成功",

                // Language settings
                "settings_language": "语言",
                "settings_language_auto": "跟随系统",
                "settings_language_english": "English",
                "settings_language_chinese": "简体中文",
                "settings_general_settings": "通用设置",

                // Common messages
                "loading": "加载中...",
                "error": "错误",
                "success": "成功",
                "cancel": "取消",
                "ok": "确定",
                "retry": "重试",
                "refresh_data": "刷新数据",
                "refresh": "刷新",
                "no_data": "暂无数据",
                "loading_failed": "加载失败",
                "network_error": "网络连接错误",
                "authentication_error": "身份验证失败，请检查您的凭据。",
                "connection_test_failed": "连接测试失败",
                "all_fields_required": "所有字段都是必填的",
                "loading_user_info": "用户信息加载完成",
                "projects_loaded": "项目加载成功",
                "projects_load_failed": "项目加载失败",
                "user_info_unavailable": "用户信息不可用",
                "check_settings": "请检查您的设置"
            ]
        ]
    }

    func localized(_ key: LocalizationKey) -> String {
        return localizations[currentLanguage]?[key.rawValue] ?? key.rawValue
    }

    func setLanguage(_ language: String) {
        if supportedLanguages.contains(language) {
            currentLanguage = language
        }
    }
}

// MARK: - Convenience Extension
extension String {
    func localized() -> String {
        if let key = LocalizationKey(rawValue: self) {
            return LocalizationManager.shared.localized(key)
        }
        return self // Return the original string if no localization key found
    }
}

// MARK: - View Extension
extension View {
    func localized(_ key: LocalizationKey) -> String {
        return LocalizationManager.shared.localized(key)
    }
}
