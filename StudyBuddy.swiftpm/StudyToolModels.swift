import Foundation
import SwiftUI

enum ToolCategory: String, CaseIterable, Identifiable {
    case studySmarter = "Study Smarter"
    case makeItStick = "Make It Stick"
    case top1Percent = "Top 1% Habits"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .studySmarter: return Color.theme.accentBlue
        case .makeItStick: return Color.theme.accentPink
        case .top1Percent: return Color.theme.accentOrange
        }
    }
}

enum Tier: String, Comparable, Codable {
    case free, pro, max
    
    static func < (lhs: Tier, rhs: Tier) -> Bool {
        switch (lhs, rhs) {
        case (.free, .pro), (.free, .max), (.pro, .max): return true
        default: return false
        }
    }
}

enum StudyTool: String, CaseIterable, Identifiable {
    // Category A
    case examOracle = "Exam Oracle"
    case knowledgeGap = "Knowledge Gap Scanner"
    case mvPlanner = "MV Study Planner"
    case smartSummarizer = "Smart Summarizer"
    case spacedRep = "Spaced Repetition Engine"
    
    // Category B
    case conceptStoryteller = "Concept Storyteller"
    case debateMode = "Debate Mode"
    case curiosityRabbitHole = "Curiosity Rabbit Hole"
    case studyStreaks = "Study Streaks & XP"
    case personalityTutor = "Personality-Matched Tutor"
    case makeItClick = "Make It Click"
    
    // Category C
    case feynmanMode = "Feynman Teacher Mode"
    case deepUnderstanding = "Deep Understanding"
    case mentalModel = "Mental Model Builder"
    case essayBrutalist = "Essay Brutalist"
    case crossSubject = "Cross-Subject Finder"
    case metacognition = "Metacognition Coach"
    case professorMode = "Professor Mode"
    
    var id: String { rawValue }
    
    var toolId: String {
        switch self {
        case .examOracle: return "examOracle"
        case .knowledgeGap: return "knowledgeGap"
        case .mvPlanner: return "mvPlanner"
        case .smartSummarizer: return "smartSummarizer"
        case .spacedRep: return "spacedRep"
        case .conceptStoryteller: return "conceptStoryteller"
        case .debateMode: return "debateMode"
        case .curiosityRabbitHole: return "curiosityRabbitHole"
        case .studyStreaks: return "studyStreaks"
        case .personalityTutor: return "personalityTutor"
        case .makeItClick: return "makeItClick"
        case .feynmanMode: return "feynmanMode"
        case .deepUnderstanding: return "deepUnderstanding"
        case .mentalModel: return "mentalModel"
        case .essayBrutalist: return "essayBrutalist"
        case .crossSubject: return "crossSubject"
        case .metacognition: return "metacognition"
        case .professorMode: return "professorMode"
        }
    }
    
    var category: ToolCategory {
        switch self {
        case .examOracle, .knowledgeGap, .mvPlanner, .smartSummarizer, .spacedRep:
            return .studySmarter
        case .conceptStoryteller, .debateMode, .curiosityRabbitHole, .studyStreaks, .personalityTutor, .makeItClick:
            return .makeItStick
        case .feynmanMode, .deepUnderstanding, .mentalModel, .essayBrutalist, .crossSubject, .metacognition, .professorMode:
            return .top1Percent
        }
    }
    
    var iconName: String {
        switch self {
        case .examOracle: return "crystalcube"
        case .knowledgeGap: return "magnifyingglass.circle"
        case .mvPlanner: return "calendar.badge.clock"
        case .smartSummarizer: return "text.alignleft"
        case .spacedRep: return "rectangle.stack.badge.play"
        case .conceptStoryteller: return "book.closed"
        case .debateMode: return "bubble.left.and.bubble.right"
        case .curiosityRabbitHole: return "hare"
        case .studyStreaks: return "flame"
        case .personalityTutor: return "person.text.rectangle"
        case .makeItClick: return "lightbulb.max"
        case .feynmanMode: return "person.wave.2"
        case .deepUnderstanding: return "brain.head.profile"
        case .mentalModel: return "network"
        case .essayBrutalist: return "hammer"
        case .crossSubject: return "arrow.left.and.right.circle"
        case .metacognition: return "eyes"
        case .professorMode: return "graduationcap"
        }
    }
    
    var requiredTier: Tier {
        switch self.category {
        case .studySmarter: return .free
        case .makeItStick: return .pro
        case .top1Percent: return .max
        }
    }
}
