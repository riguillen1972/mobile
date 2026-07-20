import Foundation
import FoundationModels

@Generable
struct RawFlashcard: Codable {
    let question: String
    let answer: String
}

@Generable
struct RawQuizQuestion: Codable {
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

struct Flashcard: Identifiable, Codable {
    let id: UUID
    let question: String
    let answer: String
    
    init(id: UUID = UUID(), question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }
}

struct QuizQuestion: Identifiable, Codable {
    let id: UUID
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    
    init(id: UUID = UUID(), question: String, options: [String], correctIndex: Int, explanation: String) {
        self.id = id
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
    }
}

@Generable
struct BibleVerse: Codable {
    let reference: String
    let text: String
    let explanation: String
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

enum MessageRole {
    case user
    case assistant
    case system
}
