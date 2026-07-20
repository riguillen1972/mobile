import Foundation
import FoundationModels

enum AIModelError: Error {
    case invalidResponse
    case decodingError(Error)
    case missingAPIKey
    case tokenLimitReached
}

struct TeacherSuggestion: Codable {
    let suggestion: String
    let recommendedTitle: String
    let recommendedSubject: String
    let recommendedType: String
    let recommendedContent: String
}

final class AIModelService: Sendable {
    static let shared = AIModelService()
    
    private init() {}
    
    private func getConfiguredModel(id: String) async throws -> Any {
        let subscriptionManager = await SubscriptionManager.shared
        
        // Determine the actual model to use. If not specified, get default for tier.
        var actualModel = id.isEmpty ? await subscriptionManager.getModelForTier() : id
        
        // If they requested a model they can't use (e.g. max model on free tier), fallback.
        if await !subscriptionManager.canUseModel(actualModel) {
            actualModel = await subscriptionManager.getModelForTier()
        }
        
        // Check if they have tokens left for this model
        if await !subscriptionManager.canUseModel(actualModel) {
            throw AIModelError.tokenLimitReached
        }
        
        if actualModel.contains("claude") {
            let session = try await SupabaseManager.shared.client.auth.session
            return ClaudeLanguageModel.proxied(
                url: URL(string: "https://studyssbuddyssai.vercel.app/api/proxy/claude")!,
                headers: ["Authorization": "Bearer \(session.accessToken)"]
            )
        } else {
            return FirebaseVertexAI.LanguageModel(name: actualModel)
        }
    }
    
    private func trackTokens(prompt: String, response: String, model: String) async {
        let estimatedTokens = (prompt.count + response.count) / 4
        let actualModel = model.isEmpty ? await SubscriptionManager.shared.getModelForTier() : model
        await SubscriptionManager.shared.incrementTokens(model: actualModel, count: estimatedTokens)
    }

    func sendMessage(messages: [ChatMessage], tutorMode: Int, model: String = "") async throws -> String {
        var instructions = ""
        if tutorMode == 0 {
            instructions = "You are an expert AI tutor. Explain concepts clearly, encourage the student, and break down complex topics."
        } else {
            instructions = "You are a research assistant. Provide concise, factual, and direct answers without educational fluff."
        }
        
        let languageModel = try await getConfiguredModel(id: model)
        let session = LanguageModelSession(model: languageModel, instructions: instructions)
        
        var promptString = ""
        for msg in messages {
            let roleName = msg.role == .user ? "Student" : "Tutor"
            promptString += "\(roleName): \(msg.content)\n"
        }
        promptString += "Tutor: "
        
        let response = try await session.respond(to: promptString)
        await trackTokens(prompt: promptString + instructions, response: response.content, model: model)
        return response.content
    }
    
    func sendMessageWithImage(prompt: String, imageData: Data, model: String = "") async throws -> String {
        let languageModel = try await getConfiguredModel(id: model)
        let session = LanguageModelSession(model: languageModel, instructions: "You are an expert AI tutor analyzing homework. Provide step-by-step solutions.")
        let response = try await session.respond(to: prompt)
        await trackTokens(prompt: prompt + "You are an expert AI tutor analyzing homework. Provide step-by-step solutions.", response: response.content, model: model)
        return response.content
    }
    
    func generateFlashcards(topic: String, model: String = "") async throws -> [Flashcard] {
        let prompt = "Generate exactly 5 flashcards about: \(topic). Return ONLY a JSON array of objects with 'question' and 'answer' string fields."
        let languageModel = try await getConfiguredModel(id: model)
        let session = LanguageModelSession(model: languageModel, instructions: "You are an API that exclusively returns raw JSON data without markdown wrappers.")
        let response = try await session.respond(to: prompt)
        
        let jsonString = response.content.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
        guard let data = jsonString.data(using: .utf8) else { throw AIModelError.invalidResponse }
        let raw = try JSONDecoder().decode([RawFlashcard].self, from: data)
        
        await trackTokens(prompt: prompt, response: "Generated 5 flashcards", model: model)
        return raw.map { Flashcard(question: $0.question, answer: $0.answer) }
    }
    
    func generateQuiz(topic: String, count: Int, model: String = "") async throws -> [QuizQuestion] {
        let prompt = "Generate exactly \(count) multiple-choice questions about: \(topic). Return ONLY a JSON array of objects with 'question', 'options' (array of strings), 'correctIndex' (integer), and 'explanation' fields."
        let languageModel = try await getConfiguredModel(id: model)
        let session = LanguageModelSession(model: languageModel, instructions: "You are an API that exclusively returns raw JSON data without markdown wrappers.")
        let response = try await session.respond(to: prompt)
        
        let jsonString = response.content.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
        guard let data = jsonString.data(using: .utf8) else { throw AIModelError.invalidResponse }
        let raw = try JSONDecoder().decode([RawQuizQuestion].self, from: data)
        
        await trackTokens(prompt: prompt, response: "Generated \(count) quiz questions", model: model)
        return raw.map { QuizQuestion(question: $0.question, options: $0.options, correctIndex: $0.correctIndex, explanation: $0.explanation) }
    }
    
    func generateBibleVerse(topic: String, model: String = "") async throws -> BibleVerse {
        let prompt = "Find a comforting or relevant Bible verse about: \(topic). Return ONLY a JSON object with 'reference', 'text', and 'explanation' string fields."
        let languageModel = try await getConfiguredModel(id: model)
        let session = LanguageModelSession(model: languageModel, instructions: "You are an API that exclusively returns raw JSON data without markdown wrappers.")
        let apiResponse = try await session.respond(to: prompt)
        
        let jsonString = apiResponse.content.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
        guard let data = jsonString.data(using: .utf8) else { throw AIModelError.invalidResponse }
        let response = try JSONDecoder().decode(BibleVerse.self, from: data)
        
        await trackTokens(prompt: prompt, response: "Generated bible verse", model: model)
        return response
    }
    
    func generateMiniApp(prompt: String, model: String = "") async throws -> String {
        let instructions = "You are an expert web developer. Generate a complete, standalone, single-file HTML document containing embedded CSS and JavaScript to fulfill the user's request. Return ONLY the raw HTML code starting with <!DOCTYPE html>. Do not wrap the response in markdown blocks."
        
        let languageModel = try await getConfiguredModel(id: model)
        let session = LanguageModelSession(model: languageModel, instructions: instructions)
        let response = try await session.respond(to: prompt)
        await trackTokens(prompt: prompt + instructions, response: response.content, model: model)
        
        var code = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if code.hasPrefix("```html") { code.removeFirst(7) }
        if code.hasPrefix("```") { code.removeFirst(3) }
        if code.hasSuffix("```") { code.removeLast(3) }
        return code.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func generateTeacherSuggestion(progress: [APIClient.ClassProgressItem], model: String = "") async throws -> TeacherSuggestion {
        let languageModel = try await getConfiguredModel(id: model)
        let session = LanguageModelSession(model: languageModel, instructions: "You are an API that exclusively returns raw JSON data without markdown wrappers. You analyze student progress to recommend the next assignment. Return ONLY a JSON object with 'suggestion', 'recommendedTitle', 'recommendedSubject', 'recommendedType' (lesson/homework/quiz/rubric), and 'recommendedContent' string fields.")
        
        var prompt = "Here are the topics students are struggling with:\n"
        for item in progress {
            prompt += "Q: \(item.question) - Wrong \(item.wrong_count) times\n"
        }
        prompt += "Provide a helpful suggestion for the teacher, and generate a recommended assignment."
        
        let response = try await session.respond(to: prompt)
        let jsonString = response.content.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
        guard let data = jsonString.data(using: .utf8) else { throw AIModelError.invalidResponse }
        let suggestion = try JSONDecoder().decode(TeacherSuggestion.self, from: data)
        
        await trackTokens(prompt: prompt, response: suggestion.suggestion, model: model)
        return suggestion
    }
    
    func generateWebTutorLesson(topic: String, model: String = "") async throws -> String {
        let instructions = "You are an educational designer. Generate a complete, standalone, interactive single-file HTML document containing embedded CSS and JavaScript that teaches the user about the requested topic. Include an interactive quiz or visual element. Return ONLY the raw HTML code starting with <!DOCTYPE html>."
        
        let languageModel = try await getConfiguredModel(id: model)
        let session = LanguageModelSession(model: languageModel, instructions: instructions)
        let response = try await session.respond(to: "Teach me about: \(topic)")
        await trackTokens(prompt: "Teach me about: \(topic)" + instructions, response: response.content, model: model)
        
        var code = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if code.hasPrefix("```html") { code.removeFirst(7) }
        if code.hasPrefix("```") { code.removeFirst(3) }
        if code.hasSuffix("```") { code.removeLast(3) }
        return code.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
