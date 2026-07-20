import SwiftUI

struct ConceptStorytellerInput: Codable {
    let concept: String
    let groundingContext: String?
}

struct ConceptStorytellerOutput: Codable {
    let story: String
    let analogy: String
}

struct ConceptStorytellerView: View {
    @State private var concept = ""
    @State private var story = ""
    @State private var analogy = ""
    @State private var isGenerating = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if story.isEmpty {
                    Text("Turn any boring concept into an unforgettable story with a memorable analogy.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    TextField("Enter a concept (e.g. Action Potentials)", text: $concept)
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: generateStory) {
                        HStack {
                            if isGenerating {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "book.closed")
                            }
                            Text(isGenerating ? "Writing Story..." : "Tell Me A Story")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(concept.isEmpty || isGenerating)
                } else {
                    Button("Start Over") {
                        withAnimation {
                            story = ""
                            analogy = ""
                            concept = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("The Analogy")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentPink)
                        
                        Text(analogy)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.theme.accentPink.opacity(0.1))
                            .cornerRadius(12)
                        
                        Divider().background(Color.gray)
                        
                        Text("The Story")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentBlue)
                        
                        Text(story)
                            .foregroundColor(.white)
                            .lineSpacing(4)
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
    
    private func generateStory() {
        isGenerating = true
        errorMessage = ""
        
        Task {
            do {
                let input = ConceptStorytellerInput(concept: concept, groundingContext: nil)
                let output: ConceptStorytellerOutput = try await StudyToolService.shared.runTool(tool: .conceptStoryteller, input: input)
                withAnimation {
                    story = output.story
                    analogy = output.analogy
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isGenerating = false
        }
    }
}
