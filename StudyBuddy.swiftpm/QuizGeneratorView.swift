import SwiftUI

struct QuizGeneratorView: View {
    let displayName: String
    
    @State private var topic = ""
    @State private var questionCount = 5
    @State private var isGenerating = false
    @State private var errorMessage = ""
    
    @State private var questions: [QuizQuestion] = []
    @State private var currentQuestionIndex = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var score = 0
    @State private var isQuizFinished = false
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quiz Generator")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.theme.textPrimary)
                        Text("Test your knowledge with AI-generated interactive quizzes.")
                            .font(.body)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    .padding(.top, 16)
                    
                    if questions.isEmpty {
                        // Configuration Form
                        VStack(alignment: .leading, spacing: 24) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.theme.accentBlue.opacity(0.2))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.theme.accentBlue, lineWidth: 1)
                                        )
                                    Image(systemName: "checkmark.circle.badge.questionmark")
                                        .foregroundColor(Color.theme.accentBlue)
                                        .font(.system(size: 24, weight: .bold))
                                }
                                Text("Create a Quiz")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.theme.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Topic")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textSecondary)
                                TextField("What should the quiz be about?", text: $topic)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .foregroundColor(Color.theme.textPrimary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Number of Questions: \\(questionCount)")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textSecondary)
                                Slider(value: Binding(get: {
                                    Double(questionCount)
                                }, set: { newVal in
                                    questionCount = Int(newVal)
                                }), in: 3...10, step: 1)
                                .accentColor(Color.theme.accentBlue)
                            }
                            
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                            
                            Button(action: {
                                guard !topic.isEmpty else { return }
                                isGenerating = true
                                errorMessage = ""
                                
                                Task {
                                    do {
                                        let fetchedQuestions = try await AIModelService.shared.generateQuiz(topic: topic, count: questionCount)
                                        await MainActor.run {
                                            self.questions = fetchedQuestions
                                            self.currentQuestionIndex = 0
                                            self.score = 0
                                            self.isQuizFinished = false
                                            self.selectedOptionIndex = nil
                                            self.isGenerating = false
                                        }
                                    } catch {
                                        await MainActor.run {
                                            self.errorMessage = "Failed to generate quiz: \\(error.localizedDescription)"
                                            self.isGenerating = false
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    if isGenerating {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Start Quiz")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [Color.theme.accentBlue, Color(red: 37/255, green: 99/255, blue: 235/255)], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(topic.isEmpty || isGenerating)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.theme.cardBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    } else if isQuizFinished {
                        // Results Screen
                        VStack(spacing: 24) {
                            Text("Quiz Complete!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 15)
                                    .frame(width: 150, height: 150)
                                
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(score) / CGFloat(questions.count))
                                    .stroke(Color.theme.accentBlue, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                    .frame(width: 150, height: 150)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack {
                                    Text("\\(score)/\\(questions.count)")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color.theme.textPrimary)
                                    Text("Score")
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                            }
                            .padding(.vertical, 32)
                            
                            Button(action: {
                                withAnimation {
                                    questions.removeAll()
                                    topic = ""
                                }
                            }) {
                                Text("Create Another Quiz")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.theme.accentBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.theme.cardBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    } else {
                        // Active Quiz View
                        let currentQ = questions[currentQuestionIndex]
                        
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Question \\(currentQuestionIndex + 1) of \\(questions.count)")
                                .font(.headline)
                                .foregroundColor(Color.theme.textSecondary)
                            
                            Text(currentQ.question)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(Color.theme.textPrimary)
                            
                            VStack(spacing: 12) {
                                ForEach(0..<currentQ.options.count, id: \.self) { index in
                                    let isSelected = selectedOptionIndex == index
                                    let isCorrect = index == currentQ.correctIndex
                                    let showResult = selectedOptionIndex != nil
                                    
                                    let optionBgColor: Color = {
                                        if showResult {
                                            if isCorrect {
                                                return Color.green.opacity(0.2)
                                            } else if isSelected {
                                                return Color.red.opacity(0.2)
                                            }
                                        }
                                        return Color.white.opacity(0.05)
                                    }()
                                    
                                    let optionBorderColor: Color = {
                                        if showResult {
                                            if isCorrect {
                                                return Color.green
                                            } else if isSelected {
                                                return Color.red
                                            } else {
                                                return Color.white.opacity(0.1)
                                            }
                                        } else {
                                            return isSelected ? Color.theme.accentBlue : Color.white.opacity(0.1)
                                        }
                                    }()
                                    
                                    Button(action: {
                                        guard selectedOptionIndex == nil else { return }
                                        selectedOptionIndex = index
                                        if index == currentQ.correctIndex {
                                            score += 1
                                        }
                                    }) {
                                        HStack {
                                            Text(currentQ.options[index])
                                                .foregroundColor(Color.theme.textPrimary)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                            if showResult {
                                                if isCorrect {
                                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                                } else if isSelected {
                                                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                                }
                                            }
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(optionBgColor)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(optionBorderColor, lineWidth: 1)
                                        )
                                    }
                                    .disabled(showResult)
                                }
                            }
                            
                            if selectedOptionIndex != nil {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Explanation")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.theme.textPrimary)
                                    Text(currentQ.explanation)
                                        .font(.body)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                
                                Button(action: {
                                    if currentQuestionIndex < questions.count - 1 {
                                        withAnimation {
                                            currentQuestionIndex += 1
                                            selectedOptionIndex = nil
                                        }
                                    } else {
                                        withAnimation {
                                            isQuizFinished = true
                                        }
                                        Task {
                                            let finalScore = Int((Double(score) / Double(questions.count)) * 100)
                                            try? await ProgressService.shared.logActivity(type: "Quiz", durationMinutes: questions.count, score: finalScore)
                                        }
                                    }
                                }) {
                                    Text(currentQuestionIndex < questions.count - 1 ? "Next Question" : "See Results")
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.theme.accentBlue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.theme.cardBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}
