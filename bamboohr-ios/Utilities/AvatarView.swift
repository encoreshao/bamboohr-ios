import SwiftUI

// MARK: - Avatar Helper Extension
extension String {
    func getInitials() -> String {
        let words = self.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        if words.count >= 2 {
            let firstInitial = String(words[0].prefix(1)).uppercased()
            let secondInitial = String(words[1].prefix(1)).uppercased()
            return "\(firstInitial)\(secondInitial)"
        } else if words.count == 1 {
            let firstWord = words[0]
            if firstWord.count >= 2 {
                let firstChar = String(firstWord.prefix(1)).uppercased()
                let secondChar = String(firstWord.dropFirst().prefix(1)).uppercased()
                return "\(firstChar)\(secondChar)"
            } else {
                return String(firstWord.prefix(1)).uppercased()
            }
        } else {
            return "?"
        }
    }
}

// MARK: - Authenticated Avatar Image Component
struct AuthenticatedAvatarImage: View {
    let url: URL
    let size: CGFloat

    @State private var image: Image? = nil
    @State private var loadFailed = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if loadFailed || !isLoading {
                // 显示后备头像
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: size * 0.6))
                            .foregroundColor(.gray)
                    )
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

    private func fetchImage() {
        guard let settings = KeychainManager.shared.loadAccountSettings() else {
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
                    print("DEBUG: Avatar image fetch error: \(error.localizedDescription)")
                    self.loadFailed = true
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Avatar image response status: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        self.loadFailed = true
                        return
                    }
                }

                if let data = data, let uiImage = UIImage(data: data) {
                    self.image = Image(uiImage: uiImage)
                } else {
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
                AuthenticatedAvatarImage(url: url, size: size)
            } else {
                // 使用后备头像（对于默认头像URL或无头像的情况）
                fallbackAvatar
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackAvatar: some View {
        Circle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
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
        AvatarView(name: "John Smith", photoUrl: nil, size: 80)
        AvatarView(name: "张三", photoUrl: nil, size: 50)
        AvatarView(name: "SingleName", photoUrl: nil, size: 36)
    }
    .padding()
}
