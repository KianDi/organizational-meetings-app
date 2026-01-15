import Supabase
import SwiftUI

/// Configuration for Supabase client with environment injection support.
/// Provides a shared SupabaseClient instance and SwiftUI environment integration.
enum SupabaseConfig {
    // MARK: - Configuration

    /// Supabase project URL (loaded from Secrets.swift)
    static let url = URL(string: Secrets.supabaseURL)!

    /// Supabase anonymous key (loaded from Secrets.swift)
    static let anonKey = Secrets.supabaseAnonKey

    // MARK: - Shared Client

    /// Shared Supabase client instance
    /// Used throughout the app for authentication and database operations
    static let shared = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )
}

// MARK: - SwiftUI Environment

/// Environment key for injecting SupabaseClient into SwiftUI views
struct SupabaseClientKey: EnvironmentKey {
    static let defaultValue: SupabaseClient = SupabaseConfig.shared
}

extension EnvironmentValues {
    /// Access Supabase client from SwiftUI environment
    var supabase: SupabaseClient {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}
