import Foundation

/// Secret credentials for Supabase - NOT committed to git
/// Configure with your actual Supabase project credentials
enum Secrets {
  /// Your Supabase project URL
  /// Format: https://YOUR_PROJECT_ID.supabase.co
  static let supabaseURL = "https://cakseaemzhabfncvhdzv.supabase.co"

  /// Your Supabase anonymous (public) key
  /// Found in: Supabase Dashboard → Settings → API → anon/public key
  static let supabaseAnonKey = "sb_publishable_Ggeo2AxQBctGAB-lXTy0_w_auXnwDD2"
}
