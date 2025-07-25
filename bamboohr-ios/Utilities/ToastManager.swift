//
//  ToastManager.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI
import Combine

enum ToastType {
    case success
    case error
    case info
    case warning

    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        case .warning:
            return .orange
        }
    }

    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        }
    }
}

struct ToastData: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval

    init(message: String, type: ToastType, duration: TimeInterval = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }

    // Equatable conformance
    static func == (lhs: ToastData, rhs: ToastData) -> Bool {
        return lhs.id == rhs.id
    }
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var toasts: [ToastData] = []

    private init() {}

    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        let toast = ToastData(message: message, type: type, duration: duration)

        DispatchQueue.main.async {
            self.toasts.append(toast)

            // 自动隐藏Toast
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.dismiss(toast)
            }
        }
    }

    func dismiss(_ toast: ToastData) {
        DispatchQueue.main.async {
            self.toasts.removeAll { $0.id == toast.id }
        }
    }

    func dismissAll() {
        DispatchQueue.main.async {
            self.toasts.removeAll()
        }
    }

    // 便捷方法
    func success(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .success, duration: duration)
    }

    func error(_ message: String, duration: TimeInterval = 4.0) {
        show(message, type: .error, duration: duration)
    }

    func info(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .info, duration: duration)
    }

    func warning(_ message: String, duration: TimeInterval = 3.5) {
        show(message, type: .warning, duration: duration)
    }
}

struct ToastView: View {
    let toast: ToastData
    let onDismiss: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .foregroundColor(toast.type.color)
                .font(.system(size: 20, weight: .semibold))

            Text(toast.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .opacity(opacity)
        .offset(y: dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dragOffset = CGSize(width: 0, height: -200)
                            opacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
            }
        }
    }
}

struct ToastContainerView: View {
    @ObservedObject var toastManager = ToastManager.shared

    var body: some View {
        VStack(spacing: 8) {
            ForEach(toastManager.toasts) { toast in
                ToastView(toast: toast) {
                    toastManager.dismiss(toast)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: toastManager.toasts)
    }
}

// MARK: - View Modifier for easy integration
struct ToastModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                ToastContainerView()
                Spacer()
            }
        }
    }
}

extension View {
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}