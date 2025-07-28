import SwiftUI

// MARK: - Avatar Helper Extension
extension String {
    func getInitials() -> String {
        let trimmedName = self.trimmingCharacters(in: .whitespacesAndNewlines)

        // 如果是空字符串，返回问号
        guard !trimmedName.isEmpty else {
            return "?"
        }

        let words = trimmedName.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        if words.count >= 2 {
            // 有多个单词，取前两个单词的首字母
            let firstInitial = String(words[0].prefix(1)).uppercased()
            let secondInitial = String(words[1].prefix(1)).uppercased()
            return "\(firstInitial)\(secondInitial)"
        } else if words.count == 1 {
            let singleWord = words[0]

            // 检查是否为中文姓名（通常2-4个字符）
            if singleWord.unicodeScalars.allSatisfy({ CharacterSet(charactersIn: "\u{4e00}"..."\u{9fff}").contains($0) }) {
                // 中文姓名处理
                if singleWord.count >= 2 {
                    // 取前两个字符
                    let firstChar = String(singleWord.prefix(1))
                    let secondChar = String(singleWord.dropFirst().prefix(1))
                    return "\(firstChar)\(secondChar)"
                } else {
                    // 只有一个中文字符，重复显示
                    return String(singleWord.prefix(1))
                }
            } else {
                // 英文或其他语言处理
                if singleWord.count >= 2 {
                    let firstChar = String(singleWord.prefix(1)).uppercased()
                    let secondChar = String(singleWord.dropFirst().prefix(1)).uppercased()
                    return "\(firstChar)\(secondChar)"
                } else {
                    // 只有一个字符，重复显示
                    let char = String(singleWord.prefix(1)).uppercased()
                    return "\(char)\(char)"
                }
            }
        } else {
            return "?"
        }
    }

    // 基于字符串生成一致的颜色
    func generateAvatarColors() -> (Color, Color) {
        let hash = self.hash
        let hue1 = Double(abs(hash) % 360) / 360.0
        let hue2 = Double(abs(hash.multipliedReportingOverflow(by: 7).partialValue) % 360) / 360.0

        // 确保颜色有足够的饱和度和亮度
        let color1 = Color(hue: hue1, saturation: 0.7, brightness: 0.8)
        let color2 = Color(hue: hue2, saturation: 0.6, brightness: 0.9)

        return (color1, color2)
    }
}

// MARK: - Authenticated Avatar Image Component
struct AuthenticatedAvatarImage: View {
    let url: URL
    let name: String
    let size: CGFloat

    @State private var image: Image? = nil
    @State private var loadFailed = false
    @State private var isLoading = true

    private var fontSize: CGFloat {
        size * 0.35 // 字体大小为头像大小的35%
    }

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if loadFailed || !isLoading {
                // 显示基于姓名首字母的默认头像
                fallbackAvatar
            } else {
                // 加载中状态
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .scaleEffect(0.8)
                    )
            }
        }
        .onAppear {
            fetchImage()
        }
    }

    private var fallbackAvatar: some View {
        let (color1, color2) = name.generateAvatarColors()

        return Circle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [color1, color2]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: size, height: size)
            .overlay(
                Text(name.getInitials())
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(.white)
            )
    }

    private func fetchImage() {
        guard let settings = KeychainManager.shared.loadAccountSettings() else {
            print("DEBUG: No account settings found, showing fallback avatar for: \(name)")
            loadFailed = true
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        let authString = "Basic " + "\(settings.apiKey):x".data(using: .utf8)!.base64EncodedString()
        request.setValue(authString, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0 // 设置超时

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    print("DEBUG: Avatar image fetch error for \(self.name): \(error.localizedDescription), showing fallback avatar")
                    self.loadFailed = true
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Avatar image response status for \(self.name): \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 404 {
                        print("DEBUG: Avatar not found (404) for \(self.name), showing fallback avatar with initials")
                        self.loadFailed = true
                        return
                    } else if httpResponse.statusCode != 200 {
                        print("DEBUG: Avatar fetch failed with status \(httpResponse.statusCode) for \(self.name), showing fallback avatar")
                        self.loadFailed = true
                        return
                    }
                }

                if let data = data, let uiImage = UIImage(data: data) {
                    print("DEBUG: Avatar image loaded successfully for \(self.name)")
                    self.image = Image(uiImage: uiImage)
                } else {
                    print("DEBUG: Avatar image data invalid for \(self.name), showing fallback avatar")
                    self.loadFailed = true
                }
            }
        }.resume()
    }
}

// MARK: - Avatar View Component
struct AvatarView: View {
    let name: String
    let photoUrl: String?
    let size: CGFloat

    private var fontSize: CGFloat {
        size * 0.35 // 字体大小为头像大小的35%
    }

    var body: some View {
        Group {
            if let photoUrlString = photoUrl,
               let url = URL(string: photoUrlString),
               !photoUrlString.contains("photo_person_160x160") { // 不是默认头像URL
                AuthenticatedAvatarImage(url: url, name: name, size: size)
            } else {
                // 使用后备头像（对于默认头像URL或无头像的情况）
                fallbackAvatar
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackAvatar: some View {
        let (color1, color2) = name.generateAvatarColors()

        return Circle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [color1, color2]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: size, height: size)
            .overlay(
                Text(name.getInitials())
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 15) {
            AvatarView(name: "John Smith", photoUrl: nil, size: 60)
            AvatarView(name: "张三", photoUrl: nil, size: 60)
            AvatarView(name: "李四", photoUrl: nil, size: 60)
        }

        HStack(spacing: 15) {
            AvatarView(name: "Alice Johnson", photoUrl: nil, size: 50)
            AvatarView(name: "王小明", photoUrl: nil, size: 50)
            AvatarView(name: "SingleName", photoUrl: nil, size: 50)
        }

        HStack(spacing: 15) {
            AvatarView(name: "Bob Wilson", photoUrl: nil, size: 40)
            AvatarView(name: "A", photoUrl: nil, size: 40)
            AvatarView(name: "", photoUrl: nil, size: 40)
        }

        Text("每个姓名都有独特的颜色")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}
