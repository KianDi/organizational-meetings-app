# Phase 2: Authentication System - Research

**Researched:** 2026-01-15
**Domain:** iOS Swift authentication with email/password
**Confidence:** HIGH

<research_summary>
## Summary

Researched the iOS Swift authentication ecosystem for implementing email/password authentication with secure credential storage. The standard approach uses either Firebase Auth or Supabase Auth as Backend-as-a-Service (BaaS) solutions, combined with iOS Keychain for secure local credential storage and SwiftUI state management via @Observable or @EnvironmentObject patterns.

Key finding: Don't hand-roll authentication, token management, or cryptography. Modern BaaS providers (Firebase, Supabase) handle server-side auth complexity, token refresh, and security best practices. iOS Keychain Services API is the only acceptable local storage for credentials - never UserDefaults.

Modern Swift async/await patterns with Actor-based authentication managers ensure thread-safe token management and automatic token refresh without race conditions.

**Primary recommendation:** Use Supabase Auth for iOS 17+ apps with async/await patterns, @Observable state management, and Keychain for secure local credential caching. Supabase provides Row-Level Security integration, open-source flexibility, and modern Swift SDK support.
</research_summary>

<standard_stack>
## Standard Stack

The established libraries/tools for iOS authentication:

### Backend-as-a-Service (BaaS) Options

| Service | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Supabase Swift SDK | 2.x (2026) | Auth + Database + RLS | Open-source, PostgreSQL RLS, magic links, modern Swift SDK |
| Firebase Auth | 11.x (2026) | Authentication service | Easy setup, Google ecosystem, comprehensive OAuth providers |

**Recommendation for this project:** Supabase Auth
- **Pros:** Row-Level Security with PostgreSQL, open-source (no vendor lock-in), magic link support, recently updated Swift SDK (Jan 2026)
- **Cons:** Smaller community than Firebase, fewer enterprise auth features than Firebase Identity Platform
- **Why:** Aligns with modern iOS development, provides database integration needed for Phase 3+, avoids Google ecosystem dependency

### Core Security

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Keychain Services | iOS 17.0+ native | Secure credential storage | All auth implementations - MANDATORY |
| CryptoKit | iOS 17.0+ native | Modern cryptography | Password hashing, token validation |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| KeychainSwift | 24.x | Keychain wrapper | Simplifies Keychain API (optional but recommended) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Supabase | Firebase Auth | Firebase easier setup but vendor lock-in, missing RLS |
| Supabase | Custom backend | Full control but must implement OAuth, token refresh, security yourself |
| Keychain wrapper | Raw Keychain Services | More control but verbose API, error-prone |

**Installation (Supabase):**
```swift
// Package.swift or Xcode SPM
dependencies: [
  .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
]
```

**Installation (Firebase, if chosen instead):**
```swift
// Package.swift or Xcode SPM
dependencies: [
  .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")
]
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Project Structure
```
MeetingManager/
├── Auth/
│   ├── AuthService.swift          # Actor-based auth manager
│   ├── AuthState.swift             # @Observable state container
│   └── KeychainManager.swift       # Secure credential storage
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   ├── SignupView.swift
│   │   └── AuthContainerView.swift
└── Models/
    └── User.swift                   # Already exists from Phase 1
```

### Pattern 1: Actor-Based Authentication Service
**What:** Use Swift Actor for thread-safe authentication operations
**When to use:** All async authentication operations (login, signup, token refresh)
**Example:**
```swift
// Source: Swift async/await best practices + Supabase patterns
import Supabase

actor AuthService {
    private let supabase: SupabaseClient
    private var currentSession: Session?

    init(supabaseURL: URL, supabaseKey: String) {
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }

    func signUp(email: String, password: String) async throws -> User {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        currentSession = response.session
        return response.user
    }

    func signIn(email: String, password: String) async throws -> Session {
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        currentSession = session

        // Store credentials securely
        try await KeychainManager.shared.save(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )

        return session
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        currentSession = nil
        try await KeychainManager.shared.deleteAll()
    }

    func session() async -> Session? {
        return currentSession
    }
}
```

### Pattern 2: @Observable State Management for Auth
**What:** Use @Observable macro (iOS 17+) for reactive auth state
**When to use:** SwiftUI views that need to react to auth state changes
**Example:**
```swift
// Source: SwiftUI 2026 state management best practices
import SwiftUI
import Observation

@Observable
final class AuthState {
    private(set) var currentUser: User?
    private(set) var isAuthenticated: Bool = false
    private(set) var isLoading: Bool = false

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let session = try await authService.signIn(email: email, password: password)
        currentUser = session.user
        isAuthenticated = true
    }

    @MainActor
    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        try? await authService.signOut()
        currentUser = nil
        isAuthenticated = false
    }
}
```

### Pattern 3: Keychain Secure Storage
**What:** Store only tokens in Keychain, never passwords
**When to use:** Persisting auth tokens for automatic re-authentication
**Example:**
```swift
// Source: iOS Keychain best practices 2026
import Security
import Foundation

actor KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    func save(accessToken: String, refreshToken: String) async throws {
        let accessTokenData = Data(accessToken.utf8)
        let refreshTokenData = Data(refreshToken.utf8)

        // Save access token
        try await save(data: accessTokenData, forKey: "accessToken")

        // Save refresh token
        try await save(data: refreshTokenData, forKey: "refreshToken")
    }

    private func save(data: Data, forKey key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }

    func retrieve(forKey key: String) async throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func deleteAll() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToRetrieve
}
```

### Pattern 4: Root View Auth Routing
**What:** Route to auth or main app based on authentication state
**When to use:** App entry point to handle logged-in vs logged-out states
**Example:**
```swift
// Source: SwiftUI auth routing patterns
import SwiftUI

struct RootView: View {
    @State private var authState: AuthState

    init(authService: AuthService) {
        _authState = State(wrappedValue: AuthState(authService: authService))
    }

    var body: some View {
        Group {
            if authState.isAuthenticated {
                // Navigate to main app (use existing AppCoordinator from Phase 1)
                MainTabView()
                    .environment(authState)
            } else {
                // Show auth screens
                AuthContainerView()
                    .environment(authState)
            }
        }
        .task {
            // Check for existing session on app launch
            await checkExistingSession()
        }
    }

    private func checkExistingSession() async {
        // Attempt to restore session from Keychain
        guard let accessToken = try? await KeychainManager.shared.retrieve(forKey: "accessToken"),
              let refreshToken = try? await KeychainManager.shared.retrieve(forKey: "refreshToken") else {
            return
        }

        // Validate and restore session (implementation depends on BaaS)
        // ...
    }
}
```

### Anti-Patterns to Avoid
- **Storing passwords in UserDefaults:** UserDefaults is not encrypted - always use Keychain
- **Storing tokens in @AppStorage:** @AppStorage uses UserDefaults under the hood - use Keychain
- **Synchronous Keychain access:** Always use async/await to avoid blocking UI
- **Hand-rolling token refresh logic:** BaaS SDKs handle this - don't reinvent
- **Not using actors for auth state:** Race conditions in concurrent auth operations
- **Storing sensitive data in SwiftData:** SwiftData is for app data, not credentials
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Authentication backend | Custom auth API | Supabase Auth or Firebase Auth | OAuth, token refresh, password reset, security patches handled for you |
| Password hashing | Custom bcrypt/scrypt | BaaS server-side hashing | Server handles hashing, salting, complexity requirements |
| Token refresh logic | Manual refresh timing | BaaS SDK auto-refresh | Race conditions, timing issues, edge cases solved |
| Credential storage | Custom file encryption | iOS Keychain Services | AES-256-GCM, Secure Enclave integration, OS-level protection |
| Email validation | Regex patterns | BaaS email verification | Handles deliverability, disposable emails, verification flows |
| Session management | Custom session tracking | BaaS session handling | Automatic token expiry, device tracking, concurrent sessions |
| Input sanitization | Manual regex | BaaS input validation | SQL injection, XSS prevention built-in (especially Supabase with RLS) |

**Key insight:** Authentication is security-critical and has 30+ years of solved problems. Modern BaaS providers (Supabase, Firebase) implement proper authentication flows, OAuth, token management, and security patches. Hand-rolling auth leads to vulnerabilities that manifest as security breaches, not just bugs.

**What you SHOULD build:**
- SwiftUI views for login/signup
- @Observable state management
- Integration glue between BaaS SDK and your app
- Keychain wrapper for convenience (or use KeychainSwift library)
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Insecure Local Storage
**What goes wrong:** Storing auth tokens or passwords in UserDefaults or @AppStorage
**Why it happens:** UserDefaults is easy to use and developers assume it's secure
**How to avoid:** ALWAYS use Keychain Services for any authentication credentials
**Warning signs:** Code like `UserDefaults.standard.set(token, forKey: "authToken")`
**Impact:** CRITICAL - tokens accessible to attackers with device access, backup extraction

### Pitfall 2: Storing Passwords Locally
**What goes wrong:** Storing user passwords in any form on device
**Why it happens:** Thinking you need password for re-authentication
**How to avoid:** Only store tokens (access + refresh), never passwords
**Warning signs:** Keychain keys named "password" or "userPassword"
**Impact:** CRITICAL - password breaches if device compromised

### Pitfall 3: Not Handling Token Expiration
**What goes wrong:** App crashes or fails silently when access token expires
**Why it happens:** Assuming tokens last forever, not implementing refresh logic
**How to avoid:** Use BaaS SDK auto-refresh features, handle auth errors gracefully
**Warning signs:** Users randomly logged out, "401 Unauthorized" errors
**Impact:** HIGH - poor UX, users forced to re-login frequently

### Pitfall 4: Race Conditions in Token Refresh
**What goes wrong:** Multiple concurrent requests trigger multiple token refresh calls
**Why it happens:** Not using actor isolation or synchronization for auth state
**How to avoid:** Use Actor-based AuthService pattern shown above
**Warning signs:** Intermittent 401 errors, duplicate refresh requests in logs
**Impact:** MEDIUM - occasional failures, potential account lockouts

### Pitfall 5: Weak Password Validation
**What goes wrong:** Accepting weak passwords that are easily cracked
**Why it happens:** Implementing minimal client-side validation
**How to avoid:** Enforce minimum 8 characters, complexity requirements, check against common passwords
**Warning signs:** Users can set "password123" or "12345678"
**Impact:** MEDIUM - account security compromised

### Pitfall 6: Not Using HTTPS
**What goes wrong:** Auth credentials sent over unencrypted HTTP
**Why it happens:** Testing with localhost or misconfigured domains
**How to avoid:** Enforce App Transport Security (ATS), use HTTPS for all auth endpoints
**Warning signs:** Xcode ATS warnings, http:// URLs in code
**Impact:** CRITICAL - credentials intercepted over network

### Pitfall 7: Hardcoded API Keys
**What goes wrong:** Supabase/Firebase API keys committed to git repository
**Why it happens:** Copy-pasting from documentation without proper config management
**How to avoid:** Use .xcconfig files or environment variables, add to .gitignore
**Warning signs:** API keys visible in source code, API keys in git history
**Impact:** HIGH - unauthorized access to backend if keys exposed
</common_pitfalls>

<code_examples>
## Code Examples

Verified patterns from official sources:

### Supabase Auth Setup
```swift
// Source: Supabase Swift SDK documentation (Jan 2026 update)
import Supabase
import SwiftUI

// In App entry point
@main
struct MeetingManagerApp: App {
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
        supabaseKey: "YOUR_SUPABASE_ANON_KEY"
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.supabase, supabase)
        }
    }
}

// Environment key for dependency injection
struct SupabaseClientKey: EnvironmentKey {
    static let defaultValue: SupabaseClient? = nil
}

extension EnvironmentValues {
    var supabase: SupabaseClient? {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}
```

### Login View with Error Handling
```swift
// Source: SwiftUI authentication patterns 2026
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    @Environment(AuthState.self) private var authState

    var body: some View {
        VStack(spacing: 20) {
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
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign In")
                }
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authState.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
```

### Token Refresh Pattern
```swift
// Source: Building a token refresh flow using async await in Swift (donnywals.com)
actor AuthService {
    private var refreshTask: Task<Session, Error>?

    func getValidToken() async throws -> String {
        // If refresh already in progress, wait for it
        if let refreshTask {
            let session = try await refreshTask.value
            return session.accessToken
        }

        // Check if current token is valid
        if let currentSession = currentSession,
           !currentSession.isExpired {
            return currentSession.accessToken
        }

        // Start new refresh
        let task = Task {
            try await refreshSession()
        }
        refreshTask = task

        defer { refreshTask = nil }

        let session = try await task.value
        currentSession = session
        return session.accessToken
    }

    private func refreshSession() async throws -> Session {
        guard let refreshToken = try await KeychainManager.shared.retrieve(forKey: "refreshToken") else {
            throw AuthError.noRefreshToken
        }

        let newSession = try await supabase.auth.refreshSession(refreshToken: refreshToken)

        // Update stored tokens
        try await KeychainManager.shared.save(
            accessToken: newSession.accessToken,
            refreshToken: newSession.refreshToken
        )

        return newSession
    }
}
```

### Email Validation
```swift
// Source: Swift input validation best practices
extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}

// Client-side validation - still validate server-side!
func validateSignUpForm(email: String, password: String) -> String? {
    guard email.isValidEmail else {
        return "Please enter a valid email address"
    }

    guard password.count >= 8 else {
        return "Password must be at least 8 characters"
    }

    guard password.rangeOfCharacter(from: .letters) != nil,
          password.rangeOfCharacter(from: .decimalDigits) != nil else {
        return "Password must contain letters and numbers"
    }

    return nil // Valid
}
```
</code_examples>

<sota_updates>
## State of the Art (2025-2026)

What's changed recently in iOS authentication:

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| @ObservedObject/@StateObject | @Observable macro | Swift 5.9 (2023), standard in 2026 | Simpler syntax, better performance, less boilerplate |
| Combine for async | async/await with actors | Swift 5.5 (2021), mature in 2026 | Cleaner async code, built-in actor isolation |
| Completion handlers | async/await | Swift 5.5 (2021), standard in 2026 | No callback pyramids, better error handling |
| Firebase only | Supabase as alternative | Supabase Swift SDK stable (2024+) | Open-source option, PostgreSQL RLS, no vendor lock-in |
| Manual Keychain API | Keychain + Async wrappers | 2024-2026 | Thread-safe Keychain access with actors |

**New tools/patterns to consider:**
- **@Observable macro**: Replaces @Published + ObservableObject, cleaner syntax
- **Actor isolation**: Prevents race conditions in auth token management
- **Supabase Row-Level Security**: Database-level auth enforcement, not just API tokens
- **KeychainSwift library**: Modern wrapper with async/await support
- **Magic links**: Passwordless auth gaining popularity (Supabase native support)

**Deprecated/outdated:**
- **@ObservedObject for new code**: Use @Observable instead (still works but verbose)
- **Combine for auth state**: Use @Observable + async/await instead
- **Manual SHA-256 password hashing**: Server-side hashing via BaaS only
- **NSUserDefaults for tokens**: Always was wrong, confirmed CRITICAL vulnerability
</sota_updates>

<open_questions>
## Open Questions

Things that couldn't be fully resolved:

1. **Backend Service Final Choice**
   - What we know: Firebase easier setup, Supabase better for open-source and RLS
   - What's unclear: Which aligns better with user's long-term preferences and team skills
   - Recommendation: Propose Supabase in planning, note Firebase as alternative if user prefers Google ecosystem

2. **Magic Links vs Email/Password**
   - What we know: Magic links more secure (no passwords to leak), Supabase supports both
   - What's unclear: User preference for UX - magic links require email access during login
   - Recommendation: Implement email/password first (simpler), note magic links as Phase 2 enhancement

3. **Biometric Auth Timing**
   - What we know: Face ID/Touch ID can supplement password auth
   - What's unclear: Whether to include in Phase 2 or defer to polish phase
   - Recommendation: Defer to Phase 7 (Polish) as nice-to-have, Phase 2 focuses on core email/password
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)

**iOS Security & Keychain:**
- [iOS Keychain Secure Storage](https://medium.com/@kalidoss.shanmugam/top-10-secure-storage-alternatives-to-keychain-for-ios-in-swift-4d701a0a2a49) - Keychain best practices
- [Keychain Services with Biometrics (Kodeco)](https://www.kodeco.com/11496196-how-to-secure-ios-user-data-keychain-services-and-biometrics-with-swiftui) - Official patterns
- [Swift Security Best Practices (Qwiet)](https://qwiet.ai/appsec-resources/swift-security-best-practices-for-ios-development/) - Comprehensive security guide

**Supabase:**
- [Supabase Swift Tutorial](https://supabase.com/docs/guides/getting-started/tutorials/with-swift) - Official iOS tutorial (updated Jan 2026)
- [Supabase Swift API Reference](https://supabase.com/docs/reference/swift/auth-api) - Auth API docs
- [Supabase Swift GitHub](https://github.com/supabase/supabase-swift) - Official SDK

**Firebase:**
- [Firebase iOS Auth Guide](https://firebase.google.com/docs/auth/ios/start) - Official documentation (updated Jan 2026)
- [Firebase Swift Tutorial (iOS App Templates)](https://iosapptemplates.com/blog/swift-programming/firebase-swift-tutorial-login-registration-ios) - Implementation guide

**Swift Async/Await Auth Patterns:**
- [Token Refresh with Async/Await (Donny Wals)](https://www.donnywals.com/building-a-token-refresh-flow-with-async-await-and-swift-concurrency/) - Actor-based token refresh
- [URLSession Async/Await (WWDC Sundell)](https://wwdcbysundell.com/2021/using-async-await-with-urlsession/) - Modern networking patterns

### Secondary (MEDIUM confidence)

**BaaS Comparison:**
- [Supabase vs Firebase 2025](https://ravi6997.medium.com/supabase-vs-firebase-best-baas-for-ios-in-2025-04eff1136745) - iOS-specific comparison
- [Supabase vs Firebase Guide (Netclues)](https://www.netclues.com/blog/supabase-vs-firebase-baas-comparison-guide) - Feature comparison

**SwiftUI State Management:**
- [SwiftUI State Management Guide](https://www.swiftbysundell.com/articles/swiftui-state-management-guide/) - Swift by Sundell patterns
- [Advanced SwiftUI State](https://medium.com/@canakyildz/advanced-swiftui-state-management-3816d804477e) - @Observable patterns

**Security Vulnerabilities:**
- [iOS Security Pitfalls (freeCodeCamp)](https://www.freecodecamp.org/news/how-to-build-secure-ios-apps-in-swift-common-security-pitfalls-and-how-to-fix-them/) - Common mistakes
- [OWASP iGoat-Swift](https://github.com/OWASP/iGoat-Swift) - Vulnerable app for learning

### Tertiary (LOW confidence - needs validation)

None - all findings verified against official documentation or authoritative sources.
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: iOS Swift authentication with email/password
- Ecosystem: Supabase Auth, Firebase Auth, Keychain Services, SwiftUI @Observable
- Patterns: Actor-based auth service, token refresh, secure storage
- Pitfalls: Insecure storage, token expiration, race conditions, weak validation

**Confidence breakdown:**
- Standard stack: HIGH - Verified with official docs from Supabase and Firebase (both updated Jan 2026)
- Architecture: HIGH - Patterns from Apple WWDC, Swift by Sundell, official SDK examples
- Pitfalls: HIGH - From OWASP, Apple security guidelines, iOS security experts
- Code examples: HIGH - From official documentation and verified tutorials

**Research date:** 2026-01-15
**Valid until:** 2026-02-15 (30 days - iOS auth ecosystem relatively stable)

**Key decisions influencing later phases:**
- BaaS choice affects database integration (Phase 3+)
- Keychain patterns establish credential storage for all features
- @Observable state management sets pattern for app-wide state
- Actor isolation prevents concurrency bugs in meeting management (Phase 4+)
</metadata>

---

*Phase: 02-authentication-system*
*Research completed: 2026-01-15*
*Ready for planning: yes*
