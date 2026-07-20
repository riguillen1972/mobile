import Foundation

struct ClassModel: Codable, Identifiable, Hashable {
    let id: String
    let teacher_id: String
    let name: String
    let subject: String?
    let join_code: String
    let enrollment_count: Int?
    let created_at: String
}

struct ContextPackModel: Codable, Identifiable, Hashable {
    let id: String
    let class_id: String
    let type: String
    let title: String
    let subject: String?
    let content_parsed: String?
    let status: String
    let created_at: String
}

extension APIClient {
    
    // MARK: - Classes
    
    struct ClassesResponse: Codable {
        let success: Bool?
        let data: [ClassModel]?
        let error: String?
    }
    
    struct CreateClassResponse: Codable {
        let success: Bool?
        let data: ClassModel?
        let error: String?
    }
    
    func getClasses() async throws -> [ClassModel] {
        let session = await MainActor.run { AuthState.shared.session }
        guard let session = session else { throw APIError.noSession }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("/api/classes"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Failed to fetch classes")
        }
        
        let result = try JSONDecoder().decode(ClassesResponse.self, from: data)
        return result.data ?? []
    }
    
    func createClass(name: String, subject: String) async throws -> ClassModel {
        let session = await MainActor.run { AuthState.shared.session }
        guard let session = session else { throw APIError.noSession }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("/api/classes"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["name": name, "subject": subject]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Failed to create class")
        }
        
        let result = try JSONDecoder().decode(CreateClassResponse.self, from: data)
        if let newClass = result.data {
            return newClass
        } else {
            throw APIError.serverError(result.error ?? "Unknown error")
        }
    }
    
    // MARK: - Enrollments
    
    struct EnrollResponse: Codable {
        let success: Bool?
        let message: String?
        let error: String?
    }
    
    func enrollInClass(joinCode: String) async throws -> String {
        let session = await MainActor.run { AuthState.shared.session }
        guard let session = session else { throw APIError.noSession }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("/api/enroll"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["join_code": joinCode]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(EnrollResponse.self, from: data)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(result.error ?? "Failed to enroll")
        }
        
        return result.message ?? "Successfully enrolled"
    }
    
    // MARK: - Context Packs
    
    struct ContextPacksResponse: Codable {
        let success: Bool?
        let data: [ContextPackModel]?
        let error: String?
    }
    
    struct CreateContextPackResponse: Codable {
        let success: Bool?
        let data: ContextPackModel?
        let error: String?
    }
    
    func getContextPacks(classId: String? = nil) async throws -> [ContextPackModel] {
        let session = await MainActor.run { AuthState.shared.session }
        guard let session = session else { throw APIError.noSession }
        
        var url = baseURL.appendingPathComponent("/api/context-packs")
        if let classId = classId {
            url = url.appending(queryItems: [URLQueryItem(name: "class_id", value: classId)])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Failed to fetch context packs")
        }
        
        let result = try JSONDecoder().decode(ContextPacksResponse.self, from: data)
        return result.data ?? []
    }
    
    func createContextPack(classId: String, title: String, subject: String, type: String, rawContent: String) async throws -> ContextPackModel {
        let session = await MainActor.run { AuthState.shared.session }
        guard let session = session else { throw APIError.noSession }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("/api/context-packs"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "class_id": classId,
            "title": title,
            "subject": subject,
            "type": type,
            "content_raw": rawContent
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(CreateContextPackResponse.self, from: data)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(result.error ?? "Failed to create context pack")
        }
        
        if let newPack = result.data {
            return newPack
        } else {
            throw APIError.serverError(result.error ?? "Unknown error")
        }
    }
    
    // MARK: - Class Progress
    
    struct ClassProgressItem: Codable {
        let question: String
        let answer: String
        let wrong_count: Int
        let review_count: Int
    }
    
    struct ClassProgressResponse: Codable {
        let success: Bool?
        let data: [ClassProgressItem]?
        let error: String?
    }
    
    func getClassProgress(classId: String) async throws -> [ClassProgressItem] {
        let session = await MainActor.run { AuthState.shared.session }
        guard let session = session else { throw APIError.noSession }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("/api/classes/\(classId)/progress"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Failed to fetch class progress")
        }
        
        let result = try JSONDecoder().decode(ClassProgressResponse.self, from: data)
        return result.data ?? []
    }
}
