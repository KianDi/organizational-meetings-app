import SwiftUI

struct LoginView: View {
    @Environment(AuthState.self) private var authState
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome Back")
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
                .textContentType(.password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button {
                Task {
                    await signIn()
                }
            } label: {
                if authState.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(authState.isLoading || !isFormValid)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }

    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }

    private func signIn() async {
        errorMessage = nil
        do {
            try await authState.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
