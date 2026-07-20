import Foundation
import Supabase

struct ProgressLog: Codable, Identifiable, Sendable {
    var id: UUID?
    let userId: UUID
    let activityType: String
    let durationMinutes: Int
    let score: Int?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityType = "activity_type"
        case durationMinutes = "duration_minutes"
        case score
        case createdAt = "created_at"
    }
}

final class ProgressService: Sendable {
    static let shared = ProgressService()
    private init() {}
    
    @MainActor
    func fetchLogs() async throws -> [ProgressLog] {
        guard let userId = AuthState.shared.currentUser?.id else {
            return []
        }
        
        let logs: [ProgressLog] = try await SupabaseManager.shared.client
            .from("progress_logs")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return logs
    }
    
    @MainActor
    func logActivity(type: String, durationMinutes: Int, score: Int? = nil) async throws {
        guard let userId = AuthState.shared.currentUser?.id else {
            return
        }
        
        let log = ProgressLog(
            userId: userId,
            activityType: type,
            durationMinutes: durationMinutes,
            score: score,
            createdAt: nil
        )
        
        try await SupabaseManager.shared.client
            .from("progress_logs")
            .insert(log)
            .execute()
    }
}
