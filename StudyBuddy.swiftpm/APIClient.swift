import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case noSession
    case invalidResponse(Int)
    case serverError(String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noSession: return "No active session found. Please log in again."
        case .invalidResponse(let code): return "Invalid response from server (Code: \(code))"
        case .serverError(let msg): return msg
        case .decodingError(let err): return "Decoding error: \(err.localizedDescription)"
        }
    }
}

final class APIClient: Sendable {
    static let shared = APIClient()
    
    let baseURL: URL
    
    private init() {
        var appUrl = "https://studyssbuddyssai.vercel.app"
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil),
           let envContent = try? String(contentsOfFile: envPath, encoding: .utf8) {
            for line in envContent.components(separatedBy: .newlines) {
                let parts = line.components(separatedBy: "=")
                if parts.count >= 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces)
                    if key == "EXPO_PUBLIC_APP_URL" {
                        appUrl = value
                    }
                }
            }
        }
        self.baseURL = URL(string: appUrl)!
    }
    
    struct ToolRequestWrapper<Input: Encodable>: Encodable {
        let toolId: String
        let input: Input
        let model: String?
        let classId: String?
        let contextPackId: String?
    }
    
    func runTool<Input: Encodable, Output: Decodable>(
        toolId: String,
        input: Input,
        model: String? = nil,
        classId: String? = nil,
        contextPackId: String? = nil
    ) async throws -> Output {
        let session = await MainActor.run { AuthState.shared.session }
        guard let session = session else {
            throw APIError.noSession
        }
        
        let url = baseURL.appendingPathComponent("/api/tools")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let wrapper = ToolRequestWrapper(
            toolId: toolId,
            input: input,
            model: model,
            classId: classId,
            contextPackId: contextPackId
        )
        request.httpBody = try JSONEncoder().encode(wrapper)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(0)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError("Status \(httpResponse.statusCode): \(errorMsg)")
        }
        
        do {
            return try JSONDecoder().decode(Output.self, from: data)
        } catch {
            print("Decoding error for tool \(toolId): \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    struct GamificationResponse: Codable {
        let success: Bool
        let xp_awarded: Int?
        let new_total_xp: Int?
        let current_streak: Int?
        let data: StreakData?
        let error: String?
    }
    
    struct StreakData: Codable {
        let current_streak: Int
        let longest_streak: Int
        let total_xp: Int
    }
    
    func logXP(action: String, xpAmount: Int, classId: String? = nil) async throws -> GamificationResponse {
        let session = await MainActor.run { AuthState.shared.session }
        guard let session = session else {
            throw APIError.noSession
        }
        
        let url = baseURL.appendingPathComponent("/api/gamification")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "action": action,
            "xp_amount": xpAmount,
            "class_id": classId as Any
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(0)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError("Status \(httpResponse.statusCode): \(errorMsg)")
        }
        
        return try JSONDecoder().decode(GamificationResponse.self, from: data)
    }
    
    func getGamificationData() async throws -> StreakData {
        let session = await MainActor.run { AuthState.shared.session }
        guard let session = session else {
            throw APIError.noSession
        }
        
        let url = baseURL.appendingPathComponent("/api/gamification")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(0)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError("Status \(httpResponse.statusCode): \(errorMsg)")
        }
        
        let resp = try JSONDecoder().decode(GamificationResponse.self, from: data)
        if let streakData = resp.data {
            return streakData
        } else {
            throw APIError.serverError(resp.error ?? "No data returned")
        }
    }
}
