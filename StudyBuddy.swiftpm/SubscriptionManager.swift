import Foundation
import SwiftUI



struct TokenUsage: Codable {
    var flash_lite_used: Int?
    var flash_used: Int?
    var pro_used: Int?
    var haiku_used: Int?
}

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var currentTier: Tier = .free
    @Published var tokenUsage = TokenUsage()
    
    // Limits
    let freeFlashLiteLimit = 250_000
    
    let proFlashLimit = 1_000_000
    let proProLimit = 500_000
    
    let maxFlashLimit = 2_000_000
    let maxHaikuLimit = 2_000_000
    
    private init() {}
    
    func refreshState() async {
        guard let session = AuthState.shared.session else { return }
        
        // 1. Fetch Tier
        do {
            let userResponse = try await SupabaseManager.shared.client.auth.session.user
            struct Profile: Decodable { let tier: String? }
            let profile: Profile = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .eq("id", value: userResponse.id)
                .single()
                .execute()
                .value
            
            if let tierString = profile.tier, let tier = Tier(rawValue: tierString) {
                self.currentTier = tier
            } else {
                self.currentTier = .free
            }
        } catch {
            print("Failed to fetch profile tier: \(error)")
        }
        
        // 2. Fetch Usage
        do {
            let userResponse = try await SupabaseManager.shared.client.auth.session.user
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM"
            let month = dateFormatter.string(from: Date())
            
            let usage: TokenUsage = try await SupabaseManager.shared.client
                .from("token_usage")
                .select()
                .eq("user_id", value: userResponse.id)
                .eq("month", value: month)
                .single()
                .execute()
                .value
            
            self.tokenUsage = usage
        } catch {
            print("Failed to fetch token usage: \(error)")
        }
    }
    
    func canUseModel(_ model: String) -> Bool {
        if model.contains("flash-lite") {
            if currentTier == .free {
                return (tokenUsage.flash_lite_used ?? 0) < freeFlashLiteLimit
            }
            return true // Pro/Max have implicitly high limits or different routing
        } else if model.contains("pro") {
            if currentTier == .pro {
                return (tokenUsage.pro_used ?? 0) < proProLimit
            }
            return currentTier == .max
        } else if model.contains("haiku") || model.contains("claude") {
            if currentTier == .max {
                return (tokenUsage.haiku_used ?? 0) < maxHaikuLimit
            }
            return false
        } else if model.contains("flash") {
            if currentTier == .pro {
                return (tokenUsage.flash_used ?? 0) < proFlashLimit
            } else if currentTier == .max {
                return (tokenUsage.flash_used ?? 0) < maxFlashLimit
            }
            return false
        }
        return true
    }
    
    func getModelForTier() -> String {
        switch currentTier {
        case .free:
            return "googleai/gemini-2.5-flash-lite"
        case .pro:
            // Prefer flash, fallback if needed or let user choose. Defaulting to flash.
            return "googleai/gemini-2.5-flash"
        case .max:
            return "claude-3-5-haiku-20241022"
        }
    }
    
    func incrementTokens(model: String, count: Int) async {
        guard let session = AuthState.shared.session else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let month = dateFormatter.string(from: Date())
        
        var request = URLRequest(url: APIClient.shared.baseURL.appendingPathComponent("/api/token-usage"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "tokens": count,
            "month": month
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                // Fetch the latest state to reflect UI locally
                await refreshState()
            }
        } catch {
            print("Failed to increment tokens: \(error)")
        }
    }
    
    func upgrade(to newTier: Tier) async throws {
        if newTier != .free {
            // Try StoreKit purchase if products are available (production / properly configured StoreKit testing)
            let storeKit = StoreKitManager.shared
            if storeKit.storeProducts.isEmpty {
                await storeKit.fetchProducts()
            }
            
            if !storeKit.storeProducts.isEmpty {
                // StoreKit products are available — use real Apple payment
                let transaction = try await storeKit.purchase(tier: newTier)
                guard transaction != nil else {
                    // Purchase cancelled or pending
                    return
                }
            } else {
                print("[SubscriptionManager] No StoreKit products available — upgrading via Supabase directly (dev mode).")
            }
        }
        
        let userResponse = try await SupabaseManager.shared.client.auth.session.user
        
        try await SupabaseManager.shared.client
            .from("profiles")
            .update(["tier": newTier.rawValue])
            .eq("id", value: userResponse.id)
            .execute()
            
        await refreshState()
    }
}
