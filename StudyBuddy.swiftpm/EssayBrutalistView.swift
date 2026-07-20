import SwiftUI

struct EssayBrutalistInput: Codable {
    let essayText: String
    let groundingContext: String?
}

struct EssayBrutalistOutput: Codable {
    let brutalFeedback: String
    let fluffWordsFound: [String]
    let restructuredParagraph: String
}

struct EssayBrutalistView: View {
    @State private var essayText = ""
    @State private var feedback = ""
    @State private var fluffWords: [String] = []
    @State private var restructured = ""
    
    @State private var isAnalyzing = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if feedback.isEmpty {
                    Text("Warning: Not for the faint of heart. We will tear down your fluffy writing and make it punchy.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    TextEditor(text: $essayText)
                        .frame(height: 250)
                        .padding(8)
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .overlay(
                            Text("Paste your draft here...")
                                .foregroundColor(Color.theme.textSecondary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .opacity(essayText.isEmpty ? 1 : 0),
                            alignment: .topLeading
                        )
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: analyze) {
                        HStack {
                            if isAnalyzing {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "hammer.fill")
                            }
                            Text(isAnalyzing ? "Demolishing..." : "Brutalize My Essay")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(essayText.isEmpty || isAnalyzing)
                    
                } else {
                    Button("Brutalize Another Draft") {
                        withAnimation {
                            feedback = ""
                            fluffWords = []
                            restructured = ""
                            essayText = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        if !fluffWords.isEmpty {
                            Text("Fluff Words Detected")
                                .font(.headline)
                                .foregroundColor(Color.theme.accentRed)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                ForEach(fluffWords, id: \.self) { word in
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
                        
                        Text("The Brutal Truth")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentOrange)
                        
                        Text(feedback)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                        
                        Divider().background(Color.gray)
                        
                        Text("How to actually write it (Rewritten Paragraph)")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentGreen)
                        
                        Text(restructured)
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
                let input = EssayBrutalistInput(essayText: essayText, groundingContext: nil)
                let output: EssayBrutalistOutput = try await StudyToolService.shared.runTool(tool: .essayBrutalist, input: input)
                withAnimation {
                    feedback = output.brutalFeedback
                    fluffWords = output.fluffWordsFound
                    restructured = output.restructuredParagraph
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isAnalyzing = false
        }
    }
}
