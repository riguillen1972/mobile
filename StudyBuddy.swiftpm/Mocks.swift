import Foundation
import FoundationModels

// Mock for ClaudeForFoundationModels
@available(iOS 27.0, *)
public struct ClaudeLanguageModel {
    public static func proxied(url: URL, headers: [String: String]) -> ClaudeLanguageModel {
        return ClaudeLanguageModel()
    }
}

// Mock for FirebaseVertexAI
@available(iOS 27.0, *)
public enum FirebaseVertexAI {
    public struct LanguageModel {
        public init(name: String) {}
    }
}

@available(iOS 27.0, *)
extension LanguageModelSession {
    public func generate<T: Codable>(_ type: T.Type, from prompt: String) async throws -> T {
        // Mock generation
        let jsonData = "{}".data(using: .utf8)!
        return try JSONDecoder().decode(T.self, from: jsonData)
    }
    
    // Convenience init to accept Any model
    public convenience init(model: Any, instructions: String) {
        self.init(instructions: instructions)
    }
}
