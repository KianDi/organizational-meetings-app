import SwiftUI

struct AuthContainerView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            // Tab picker
            Picker("Auth Type", selection: $selectedTab) {
                Text("Sign In").tag(0)
                Text("Sign Up").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            TabView(selection: $selectedTab) {
                LoginView()
                    .tag(0)

                SignupView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

#Preview {
    AuthContainerView()
        .environment(AuthState(authService: AuthService()))
}
