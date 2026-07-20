import Foundation

final class StudyToolService: Sendable {
    static let shared = StudyToolService()
    
    private init() {}
    
    // Generic method to run any tool
    func runTool<Input: Encodable, Output: Decodable>(
        tool: StudyTool,
        input: Input,
        classId: String? = nil,
        contextPackId: String? = nil
    ) async throws -> Output {
        return try await APIClient.shared.runTool(
            toolId: tool.toolId,
            input: input,
            classId: classId,
            contextPackId: contextPackId
        )
    }
}
