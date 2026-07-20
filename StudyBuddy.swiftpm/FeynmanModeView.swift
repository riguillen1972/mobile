import SwiftUI

struct FeynmanModeInput: Codable {
    let concept: String
    let userExplanation: String
    let groundingContext: String?
}

struct FeynmanModeOutput: Codable {
    let jargonFound: [String]
    let feedback: String
    let simpleExplanation: String
}

struct FeynmanModeView: View {
    @State private var concept = ""
    @State private var userExplanation = ""
    @State private var jargonFound: [String] = []
    @State private var feedback = ""
    @State private var simpleExplanation = ""
    
    @State private var isAnalyzing = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if feedback.isEmpty {
                    Text("Can you explain it to a 10-year-old? The Feynman Technique tests true understanding.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        TextField("Concept (e.g. Quantum Entanglement)", text: $concept)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $userExplanation)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                Text("Explain it simply here...")
                                    .foregroundColor(Color.theme.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .opacity(userExplanation.isEmpty ? 1 : 0),
                                alignment: .topLeading
                            )
                    }
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: analyze) {
                        HStack {
                            if isAnalyzing {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "microbe")
                            }
                            Text(isAnalyzing ? "Testing Understanding..." : "Submit Explanation")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(concept.isEmpty || userExplanation.isEmpty || isAnalyzing)
                    
                } else {
                    Button("Try Another Concept") {
                        withAnimation {
                            feedback = ""
                            concept = ""
                            userExplanation = ""
                            jargonFound = []
                            simpleExplanation = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        if !jargonFound.isEmpty {
                            Text("⚠️ Jargon Detected")
                                .font(.headline)
                                .foregroundColor(Color.theme.accentRed)
                            
                            HStack {
                                ForEach(jargonFound, id: \.self) { word in
                                    Text(word)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.theme.accentRed.opacity(0.2))
                                        .cornerRadius(8)
                                        .foregroundColor(Color.theme.accentRed)
                                }
                            }
                            Divider().background(Color.gray)
                        }
                        
                        Text("Teacher's Feedback")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentBlue)
                        
                        Text(feedback)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                        
                        Divider().background(Color.gray)
                        
                        Text("The Ideal Simple Explanation")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentGreen)
                        
                        Text(simpleExplanation)
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
    
    private func analyze() {
        isAnalyzing = true
        errorMessage = ""
        
        Task {
            do {
                let input = FeynmanModeInput(concept: concept, userExplanation: userExplanation, groundingContext: nil)
                let output: FeynmanModeOutput = try await StudyToolService.shared.runTool(tool: .feynmanMode, input: input)
                withAnimation {
                    jargonFound = output.jargonFound
                    feedback = output.feedback
                    simpleExplanation = output.simpleExplanation
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isAnalyzing = false
        }
    }
}
