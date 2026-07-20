import SwiftUI

struct KnowledgeGapQuizQuestion: Codable {
    let question: String
    let options: [String]
    let answer: String
}

struct GenerateQuizOutput: Codable {
    let quiz: [KnowledgeGapQuizQuestion]
}

struct QuizResult: Codable {
    let question: String
    let userAnswer: String
    let correctAnswer: String
    let isCorrect: Bool
}

struct GenerateQuizInput: Codable {
    let topic: String
    let subject: String
    let gradeLevel: String
    let numQuestions: Int
}

struct KnowledgeGapInput: Codable {
    let topic: String
    let quizResults: [QuizResult]
    let groundingContext: String?
}

struct StudyPlanAction: Codable, Hashable {
    let topic: String
    let actionItem: String
}

struct KnowledgeGapOutput: Codable {
    let weakAreas: [String]
    let studyPlan: [StudyPlanAction]
}

struct KnowledgeGapView: View {
    @State private var topic = ""
    @State private var questions: [KnowledgeGapQuizQuestion] = []
    @State private var currentQuestionIndex = 0
    @State private var selectedOptions: [String] = []
    
    @State private var weakAreas: [String] = []
    @State private var studyPlan: [StudyPlanAction] = []
    
    @State private var isGeneratingQuiz = false
    @State private var isAnalyzing = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if questions.isEmpty && studyPlan.isEmpty {
                    // Initial State
                    Text("Enter a topic to take a quick diagnostic quiz. We'll identify your weak points and generate a custom study plan.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    TextField("E.g., Cellular Respiration", text: $topic)
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: generateQuiz) {
                        HStack {
                            if isGeneratingQuiz {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(isGeneratingQuiz ? "Building Quiz..." : "Start Diagnostic")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(topic.isEmpty || isGeneratingQuiz)
                    
                } else if !questions.isEmpty && currentQuestionIndex < questions.count {
                    // Quiz State
                    let q = questions[currentQuestionIndex]
                    
                    Text("Diagnostic Quiz (\(currentQuestionIndex + 1)/\(questions.count))")
                        .font(.headline)
                        .foregroundColor(Color.theme.textSecondary)
                    
                    Text(q.question)
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    ForEach(q.options, id: \.self) { opt in
                        Button(action: {
                            selectedOptions.append(opt)
                            if currentQuestionIndex < questions.count - 1 {
                                currentQuestionIndex += 1
                            } else {
                                analyzeResults()
                            }
                        }) {
                            Text(opt)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                } else if !studyPlan.isEmpty {
                    // Results State
                    if isAnalyzing {
                        ProgressView("Analyzing weak points...")
                            .padding()
                    } else {
                        Button("Start Over") {
                            topic = ""
                            questions = []
                            currentQuestionIndex = 0
                            selectedOptions = []
                            weakAreas = []
                            studyPlan = []
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Weak Areas Identified:")
                                .font(.headline)
                                .foregroundColor(Color.theme.accentRed)
                            
                            ForEach(weakAreas, id: \.self) { area in
                                Text("• \(area)")
                                    .foregroundColor(.white)
                            }
                            
                            Divider().background(Color.gray)
                            
                            Text("Action Plan:")
                                .font(.headline)
                                .foregroundColor(Color.theme.accentGreen)
                            
                            ForEach(studyPlan, id: \.self) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.topic)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text(item.actionItem)
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.theme.cardBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private func generateQuiz() {
        isGeneratingQuiz = true
        errorMessage = ""
        
        Task {
            do {
                let input = GenerateQuizInput(topic: topic, subject: "General", gradeLevel: "College", numQuestions: 5)
                let _: GenerateQuizOutput = try await StudyToolService.shared.runTool(tool: StudyTool(rawValue: "Generate Quiz") ?? .knowledgeGap, input: input)
                // Wait, StudyTool mapping: I should probably just call APIClient.shared.runTool directly since generateQuiz is a different toolId
                let genericOutput: GenerateQuizOutput = try await APIClient.shared.runTool(toolId: "generateQuiz", input: input)
                withAnimation {
                    self.questions = genericOutput.quiz
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isGeneratingQuiz = false
        }
    }
    
    private func analyzeResults() {
        isAnalyzing = true
        errorMessage = ""
        
        var results: [QuizResult] = []
        for (i, q) in questions.enumerated() {
            let isCorrect = (q.answer == selectedOptions[i])
            results.append(QuizResult(question: q.question, userAnswer: selectedOptions[i], correctAnswer: q.answer, isCorrect: isCorrect))
        }
        
        Task {
            do {
                let input = KnowledgeGapInput(topic: topic, quizResults: results, groundingContext: nil)
                let output: KnowledgeGapOutput = try await StudyToolService.shared.runTool(tool: .knowledgeGap, input: input)
                withAnimation {
                    weakAreas = output.weakAreas
                    studyPlan = output.studyPlan
                    isAnalyzing = false
                }
            } catch {
                errorMessage = "Failed to analyze: \(error.localizedDescription)"
                isAnalyzing = false
            }
        }
    }
}
