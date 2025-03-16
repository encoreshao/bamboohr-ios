//
//  HomeView.swift
//  bamboohr-ios
//
//  Created on 2025/3/15.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: UserViewModel
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, 50)
                    } else if let error = viewModel.error {
                        ErrorView(message: error) {
                            viewModel.loadUserInfo()
                        }
                    } else if let user = viewModel.user {
                        UserProfileView(user: user)
                    } else {
                        ContentUnavailableView(
                            "User Profile Unavailable",
                            systemImage: "person.crop.circle.badge.exclamationmark",
                            description: Text("Please check your account settings and internet connection.")
                        )
                        .padding()

                        Button("Refresh") {
                            viewModel.loadUserInfo()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        // Image("40")
                        //     .resizable()
                        //     .scaledToFit()
                        //     .frame(height: 30)
                        Text("BambooHR")
                            .font(.headline)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.loadUserInfo()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                isRefreshing = true
                viewModel.loadUserInfo()
                isRefreshing = false
            }
        }
        .onAppear {
            if viewModel.user == nil && !viewModel.isLoading {
                viewModel.loadUserInfo()
            }
        }
    }
}

struct UserProfileView: View {
    let user: User

    var body: some View {
        VStack(spacing: 20) {
            // Avatar
            if let photoUrl = user.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                .padding(.bottom, 10)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }

            // User info
            Text(user.fullName)
                .font(.title)
                .fontWeight(.bold)

            Text(user.jobTitle)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(user.department)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical)

            // Additional info can be added here
            InfoRow(title: "Employee ID", value: user.id)

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("Error")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Retry") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

#Preview {
    let service = BambooHRService()
    let viewModel = UserViewModel(bambooHRService: service)
    return HomeView(viewModel: viewModel)
}
