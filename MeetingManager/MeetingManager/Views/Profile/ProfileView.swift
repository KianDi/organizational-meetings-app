import SwiftUI

/// Profile view displaying user information and account actions
struct ProfileView: View {
    // MARK: - Properties

    @Environment(AuthState.self) private var authState

    @State private var showSignOutConfirmation = false

    // MARK: - Body

    var body: some View {
        List {
            // Account section
            Section {
                if let user = authState.currentUser {
                    LabeledContent("Email", value: user.email)
                } else {
                    Text("Not signed in")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Account")
            }

            // Actions section
            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                        Spacer()
                    }
                }
            } header: {
                Text("Actions")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await authState.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileView()
            .environment(AuthState(authService: AuthService()))
    }
}
