# BambooHR iOS App

一个现代化的 iOS 应用程序，集成 BambooHR API，为员工提供便捷的人力资源管理功能。

[English](README-en.md) | 中文

## 🌟 功能特色

- 🏠 **智能主页**: 展示个人信息、工作统计和今日概览
- ⏰ **时间录入**: 便捷的工作时间记录，支持项目和任务分类
- 🏖️ **团队休假**: 实时查看团队成员休假安排，头像展示
- ⚙️ **设置管理**: 安全的账户配置和连接测试
- 🌍 **多语言支持**: 中英文自动切换，基于系统语言设置
- 🔔 **智能通知**: 优雅的 Toast 消息提示系统
- 📊 **数据统计**: 基于真实数据的工作时长和假期统计

## 🆕 最新更新

### v2.0 新功能
- ✨ **多语言支持**: 自动检测系统语言，支持中文和英文
- 🎯 **Toast 通知系统**: 替代传统弹窗，提供优雅的消息反馈
- 👤 **用户头像显示**: 团队休假页面展示真实用户头像
- 🎨 **界面优化**: 项目选择全屏宽度，更好的用户体验
- 📈 **真实数据**: 主页统计基于实际工作数据计算
- 🔄 **实时加载**: 切换日期自动加载对应时间记录

## 项目架构

### 应用结构
```
bamboohr-ios/
├── bamboohr_iosApp.swift      # 主应用入口
├── ContentView.swift          # 默认内容视图 (未使用)
├── Item.swift                 # 示例数据模型 (未使用)
├── Models/                    # 数据模型层
│   ├── User.swift             # 用户信息模型
│   ├── TimeEntry.swift        # 时间记录模型
│   ├── BambooLeaveInfo.swift  # 休假信息模型
│   ├── TimeOffBalance.swift   # 假期余额模型
│   └── AccountSettings.swift  # 账户设置模型
├── Services/                  # 网络服务层
│   └── BambooHRService.swift  # BambooHR API 服务
├── ViewModels/                # 视图模型层 (MVVM 架构)
│   ├── UserViewModel.swift    # 用户数据管理
│   ├── TimeEntryViewModel.swift # 时间录入管理
│   ├── LeaveViewModel.swift   # 休假数据管理
│   └── AccountSettingsViewModel.swift # 设置管理
├── Views/                     # 用户界面层
│   ├── MainTabView.swift      # 主导航
│   ├── HomeView.swift         # 主页视图
│   ├── TimeEntryView.swift    # 时间录入界面
│   ├── LeaveView.swift        # 休假管理界面
│   └── SettingsView.swift     # 设置界面
└── Utilities/                 # 工具类
    ├── KeychainManager.swift  # 钥匙串管理
    ├── ToastManager.swift     # Toast 通知系统
    └── LocalizationManager.swift # 多语言管理
```

## 核心功能详解

### 🌍 **多语言支持**

#### 自动语言检测
- 根据系统语言自动切换中英文
- 支持运行时语言切换
- 完整的 UI 本地化

#### LocalizationManager (`Utilities/LocalizationManager.swift`)
```swift
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    @Published var currentLanguage: String

    func localized(_ key: LocalizationKey) -> String
    func setLanguage(_ language: String)
}
```

### 🔔 **Toast 通知系统**

#### 智能消息反馈
- 成功、错误、信息、警告四种类型
- 自动消失机制
- 优雅的动画效果
- 非侵入式设计

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

### 📊 **数据模型层 (`Models/`)**

#### 用户模型 (`User.swift`)
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

#### 时间录入模型 (`TimeEntry.swift`)
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

#### 休假信息 (`BambooLeaveInfo.swift`)
```swift
struct BambooLeaveInfo {
    let id: Int
    let type: String
    let employeeId: Int?
    let name: String
    let start: String
    let end: String
    var photoUrl: String?

    var startDate: Date? { /* 日期解析 */ }
    var endDate: Date? { /* 日期解析 */ }
    var leaveDuration: Int? { /* 请假天数计算 */ }
}
```

### 🌐 **网络服务层 (`Services/`)**

#### BambooHR 服务 (`BambooHRService.swift`)
- **单例模式**: `BambooHRService.shared`
- **认证**: Basic Auth with API Key
- **多格式支持**: XML 用户数据 + JSON 其他数据
- **错误处理**: 完整的错误类型定义

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

### 🎨 **视图模型层 (`ViewModels/`)**

#### 时间录入视图模型 (`TimeEntryViewModel.swift`)
- **自动加载**: 初始化时自动加载项目和时间记录
- **日期监听**: 切换日期自动刷新记录
- **表单验证**: 智能的项目和任务验证
- **Toast 集成**: 多语言错误和成功提示

```swift
class TimeEntryViewModel: ObservableObject {
    @Published var selectedDate = Date() {
        didSet {
            if selectedDate != oldValue {
                loadTimeEntries()
            }
        }
    }

    var totalHoursForDate: Double { /* 计算当日总工时 */ }
    var formattedTotalHours: String { /* 格式化显示 */ }
}
```

### 📱 **用户界面层 (`Views/`)**

#### 主页视图 (`HomeView.swift`)
- **智能统计**: 基于真实数据的工作时长统计
- **用户信息**: 头像加载和个人信息展示
- **今日概览**: 当前工作状态和团队休假情况
- **多语言**: 完整的中英文界面

#### 时间录入视图 (`TimeEntryView.swift`)
- **全屏选择器**: 项目选择占据屏幕全宽
- **级联选择**: 项目→任务智能级联
- **记录展示**: 当前日期的时间记录列表
- **实时计算**: 总工时自动计算和显示

#### 休假视图 (`LeaveView.swift`)
- **用户头像**: 36x36 圆形头像展示
- **休假类型**: 图标化的请假类型显示
- **日期信息**: 请假开始日期和天数
- **统计概览**: 今日、明日、本周休假统计

#### 设置视图 (`SettingsView.swift`)
- **连接状态**: 实时显示连接状态
- **安全输入**: 密码字段和帮助信息
- **连接测试**: 一键测试 API 连接
- **数据清理**: 安全的设置清除功能

### 🔐 **工具类 (`Utilities/`)**

#### 钥匙串管理器 (`KeychainManager.swift`)
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

## 技术栈

### 🛠️ 开发框架
- **SwiftUI**: 声明式 UI 框架
- **SwiftData**: 本地数据持久化
- **Combine**: 响应式编程

### 🌐 网络与数据
- **URLSession**: HTTP 网络请求
- **AsyncImage**: 异步图像加载
- **JSONDecoder/XMLParser**: 多格式数据解析
- **Keychain Services**: 安全凭据存储

### 🏗️ 架构模式
- **MVVM**: Model-View-ViewModel
- **Singleton**: 服务层单例模式
- **Publisher-Subscriber**: 响应式数据流
- **Dependency Injection**: 依赖注入

## API 集成

### BambooHR REST API
- **认证方式**: API Key + Basic Auth
- **数据格式**: JSON (主要) / XML (用户数据)
- **错误处理**: 完整的错误类型系统

### 支持的端点
```
GET /v1/employees/{id}           # 获取员工信息 (XML)
GET /v1/time_off/requests        # 获取休假请求 (JSON)
GET /v1/time_tracking/projects   # 获取项目列表 (JSON)
GET /v1/time_tracking/hour_entries/{date} # 获取时间记录 (JSON)
POST /v1/time_tracking/hour_entries      # 提交时间记录 (JSON)
```

### 网络错误处理
```swift
enum BambooHRError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case authenticationError
    case networkError(Error)
    case decodingError(Error)
    case unknownError(String)

    var errorDescription: String? { /* 本地化错误描述 */ }
}
```

## 安全特性

### 🔒 数据安全
- **钥匙串存储**: API 密钥加密存储
- **HTTPS 强制**: 所有 API 请求使用 HTTPS
- **认证验证**: 实时连接测试
- **数据隔离**: 本地缓存与远程数据分离

### 🛡️ 隐私保护
- **最小权限**: 仅请求必要的用户数据
- **本地优先**: 敏感数据优先本地存储
- **自动清理**: 退出登录自动清除缓存

## 用户体验

### 🎨 界面设计
- **Material Design 3**: 现代化设计语言
- **深色模式**: 自动适配系统主题
- **响应式布局**: 适配多种设备尺寸
- **流畅动画**: 60fps 流畅交互

### 📱 交互优化
- **下拉刷新**: 手势驱动的数据更新
- **Toast 通知**: 非侵入式消息提示
- **智能加载**: 分页和懒加载优化
- **错误重试**: 网络异常自动重试

### 🔄 数据同步
- **增量更新**: 智能的数据差异同步
- **离线支持**: 无网络时的本地数据访问
- **冲突解决**: 自动处理数据冲突

## 开发要求

### 📋 系统要求
- **最低版本**: iOS 18.2+
- **开发工具**: Xcode 15.0+
- **语言版本**: Swift 5.9+
- **架构支持**: arm64, x86_64

### 🔧 依赖管理
- **Swift Package Manager**: 依赖包管理
- **内置框架**: 无第三方依赖
- **模块化设计**: 松耦合组件架构

## 配置指南

### 🚀 首次使用
1. **获取 API 密钥**
   - 登录 BambooHR 网页版
   - 导航到 API 设置页面
   - 生成新的 API 密钥

2. **配置应用**
   - 打开应用设置页面
   - 输入公司域名 (如: mycompany)
   - 填入员工 ID 和 API 密钥
   - 点击测试连接验证

3. **开始使用**
   - 连接成功后自动跳转到主页
   - 查看个人信息和工作统计
   - 开始记录工作时间

### ⚙️ 高级配置
- **语言设置**: 跟随系统语言或手动切换
- **通知偏好**: 自定义 Toast 显示时长
- **数据同步**: 配置自动同步频率
- **隐私设置**: 管理本地数据存储

### 🔍 故障排除
- **连接失败**: 检查网络和 API 密钥
- **数据不更新**: 下拉刷新或重新登录
- **界面异常**: 重启应用或清除缓存

## 开发贡献

### 🛠️ 开发环境设置
```bash
# 克隆项目
git clone https://github.com/your-repo/bamboohr-ios.git

# 打开项目
cd bamboohr-ios
open bamboohr-ios.xcodeproj
```

### 📝 代码规范
- **Swift Style Guide**: 遵循官方代码风格
- **MVVM 架构**: 严格的架构分层
- **单元测试**: 核心逻辑测试覆盖
- **文档注释**: 完整的 API 文档

### 🎯 贡献流程
1. Fork 项目仓库
2. 创建功能分支
3. 提交代码变更
4. 创建 Pull Request
5. 代码审查和合并

---

## 📄 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE) 文件。

## 🤝 支持与反馈

- **问题报告**: [GitHub Issues](https://github.com/your-repo/bamboohr-ios/issues)
- **功能建议**: [GitHub Discussions](https://github.com/your-repo/bamboohr-ios/discussions)
- **技术支持**: support@yourcompany.com

---

*最后更新时间: 2024年12月*
