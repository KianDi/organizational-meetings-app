import SwiftUI

struct SignupView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    let authService: AuthService
    let onSignupSuccess: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            SecureField("Confirm Password", text: $confirmPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            // Password requirements hint
            if !password.isEmpty && password.count < 8 {
                Text("Password must be at least 8 characters")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            Button {
                Task {
                    await signUp()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(isLoading || !isFormValid)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }

    private var isFormValid: Bool {
        email.contains("@") &&
        password.count >= 8 &&
        password == confirmPassword
    }

    private func signUp() async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.signUp(email: email, password: password)
            await MainActor.run {
                onSignupSuccess()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
