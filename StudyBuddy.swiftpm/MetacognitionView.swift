import SwiftUI

struct MetacognitionInput: Codable {
    let topic: String
    let studyMethod: String
    let groundingContext: String?
}

struct MetacognitionOutput: Codable {
    let reflectionQuestions: [String]
    let optimizationAdvice: String
}

struct MetacognitionView: View {
    @State private var topic = ""
    @State private var studyMethod = ""
    @State private var reflectionQuestions: [String] = []
    @State private var optimizationAdvice = ""
    
    @State private var isCoaching = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if reflectionQuestions.isEmpty {
                    Text("Think about how you think. Evaluate if your current study method is actually effective.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        TextField("What are you studying?", text: $topic)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        TextField("How are you studying it? (e.g. re-reading notes)", text: $studyMethod)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: getCoaching) {
                        HStack {
                            if isCoaching {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "eyes")
                            }
                            Text(isCoaching ? "Analyzing..." : "Get Metacognitive Coaching")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(topic.isEmpty || studyMethod.isEmpty || isCoaching)
                    
                } else {
                    Button("Evaluate Another Method") {
                        withAnimation {
                            reflectionQuestions = []
                            optimizationAdvice = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reflection Questions")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentBlue)
                        
                        ForEach(Array(reflectionQuestions.enumerated()), id: \.offset) { index, question in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.theme.accentBlue)
                                Text(question)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Divider().background(Color.gray)
                        
                        Text("Optimization Advice")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentGreen)
                        
                        Text(optimizationAdvice)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                    }
                    .padding()
                    .background(Color.theme.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func getCoaching() {
        isCoaching = true
        errorMessage = ""
        
        Task {
            do {
                let input = MetacognitionInput(topic: topic, studyMethod: studyMethod, groundingContext: nil)
                let output: MetacognitionOutput = try await StudyToolService.shared.runTool(tool: .metacognition, input: input)
                withAnimation {
                    reflectionQuestions = output.reflectionQuestions
                    optimizationAdvice = output.optimizationAdvice
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isCoaching = false
        }
    }
}
