import Foundation
import Supabase

final class SupabaseManager: Sendable {
    static let shared = SupabaseManager()
    let client: SupabaseClient
    
    private init() {
        var supabaseUrl = ""
        var supabaseAnonKey = ""
        
        // Try reading from bundle first
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil),
           let envContent = try? String(contentsOfFile: envPath, encoding: .utf8) {
            let lines = envContent.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.components(separatedBy: "=")
                if parts.count >= 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces)
                    
                    if key == "NEXT_PUBLIC_SUPABASE_URL" {
                        supabaseUrl = value
                    } else if key == "NEXT_PUBLIC_SUPABASE_ANON_KEY" {
                        supabaseAnonKey = value
                    }
                }
            }
        }
        
        // Fallback to hardcoded configuration if `.env` is not bundled or missing required fields
        if supabaseUrl.isEmpty || supabaseAnonKey.isEmpty {
            print("Supabase credentials not found in bundled .env. Using fallback config values.")
            supabaseUrl = "https://feccdhxvyfdogfodglpk.supabase.co"
            supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZlY2NkaHh2eWZkb2dmb2RnbHBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MzMxMzUsImV4cCI6MjA4ODUwOTEzNX0.EHsXfwI2XE_3dugSRzEmJ7OQWS89Vnh8ivVi0mzG4lU"
        }
        
        guard let url = URL(string: supabaseUrl) else {
            print("CRITICAL: Invalid Supabase URL: \(supabaseUrl)")
            // Return a client with a placeholder url to prevent fatalError crash on startup
            self.client = SupabaseClient(supabaseURL: URL(string: "https://placeholder-url.supabase.co")!, supabaseKey: "")
            return
        }
        
        print("Initializing Supabase with URL: \(url)")
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(emitLocalSessionAsInitialSession: true)
            )
        )
    }
}

