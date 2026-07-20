import Foundation
import Supabase
import SwiftUI

@MainActor
class AuthState: ObservableObject {
    @Published var session: Session?
    @Published var currentUser: User?
    @Published var userTier: String = "free"
    @Published var userRole: String?
    @Published var needsRolePicker = false
    @Published var isLoading = true
    
    static let shared = AuthState()
    
    private init() {
        Task {
            await initialize()
        }
    }
    
    func initialize() async {
        print("Initializing AuthState...")
        
        // 1. Listen to auth state changes in the background
        Task {
            for await state in SupabaseManager.shared.client.auth.authStateChanges {
                print("Auth state change received: \(state.event)")
                self.session = state.session
                self.currentUser = state.session?.user
                if let user = state.session?.user {
                    await self.fetchUserTier(uid: user.id)
                    let role = user.userMetadata["role"]?.value as? String
                    print("DEBUG: Fetched role from metadata: \(String(describing: role))")
                    self.userRole = role
                    self.needsRolePicker = (role == nil || role?.isEmpty == true)
                } else {
                    self.userTier = "free"
                    self.userRole = nil
                    self.needsRolePicker = false
                }
                self.isLoading = false
            }
        }
        
        // 2. Fetch current session concurrently to avoid blocking startup
        Task {
            do {
                print("Fetching current session...")
                let currentSession = try await SupabaseManager.shared.client.auth.session
                self.session = currentSession
                self.currentUser = currentSession.user
                await self.fetchUserTier(uid: currentSession.user.id)
                let role = currentSession.user.userMetadata["role"]?.value as? String
                print("DEBUG: Fetched role from currentSession metadata: \(String(describing: role))")
                self.userRole = role
                self.needsRolePicker = (role == nil || role?.isEmpty == true)
                print("Fetched session successfully. User logged in: \(currentSession.user.email ?? "nil")")
            } catch {
                print("No active session found or error: \(error)")
            }
            self.isLoading = false
        }
        
        // 3. Safety timeout: Force-clear loading indicator after 3 seconds if still loading
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if self.isLoading {
                print("Initialization took too long. Forcing isLoading = false to show UI.")
                self.isLoading = false
            }
        }
    }
    
    private func fetchUserTier(uid: UUID) async {
        do {
            struct Profile: Decodable { let tier: String? }
            let profile: Profile = try await SupabaseManager.shared.client
                .from("profiles")
                .select("tier")
                .eq("id", value: uid)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.userTier = profile.tier ?? "free"
            }
        } catch {
            print("Failed to fetch user tier: \(error)")
            await MainActor.run { self.userTier = "free" }
        }
    }
    
    func signOut() async {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
            self.userTier = "free"
            self.userRole = nil
            self.needsRolePicker = false
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    func updateUserRole(role: String, gradeLevel: String?, careerField: String?, classCode: String? = nil) async {
        do {
            var metadata: [String: AnyJSON] = ["role": .string(role)]
            
            // Teacher gets a generated class code, Students get the inputted class code
            if role == "teacher" {
                let generatedCode = UUID().uuidString.prefix(6).uppercased()
                metadata["class_code"] = .string(generatedCode)
            } else if let cc = classCode, !cc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                metadata["class_code"] = .string(cc.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
            }
            if let gl = gradeLevel {
                metadata["grade_level"] = .string(gl)
            }
            if let cf = careerField {
                metadata["career_field"] = .string(cf)
            }
            
            let response = try await SupabaseManager.shared.client.auth.update(
                user: UserAttributes(data: metadata)
            )
            
            await MainActor.run {
                self.currentUser = response
                self.userRole = role
                self.needsRolePicker = false
            }
        } catch {
            print("Failed to update user role: \(error)")
        }
    }
}
