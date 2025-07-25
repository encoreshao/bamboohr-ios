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

// MARK: - Avatar View Component
struct AvatarView: View {
    let name: String
    let photoUrl: String?
    let size: CGFloat

    private var fontSize: CGFloat {
        size * 0.35 // 字体大小为头像大小的35%
    }

    var body: some View {
        AsyncImage(url: URL(string: photoUrl ?? "")) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: size, height: size)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            case .failure:
                fallbackAvatar
            @unknown default:
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