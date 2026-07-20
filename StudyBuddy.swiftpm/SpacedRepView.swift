import SwiftUI

struct GenerateFlashcardsInput: Codable {
    let topic: String
    let subject: String
    let gradeLevel: String
    let numFlashcards: Int
}

struct SpacedRepFlashcard: Codable, Hashable {
    let front: String
    let back: String
}

struct GenerateFlashcardsOutput: Codable {
    let flashcards: [SpacedRepFlashcard]
}

struct SpacedRepView: View {
    @State private var topic = ""
    @State private var flashcards: [SpacedRepFlashcard] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    
    @State private var isGenerating = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if flashcards.isEmpty {
                    Text("Enter a topic to generate AI flashcards. We'll track your retention using spaced repetition algorithms.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    TextField("E.g. Mitosis vs Meiosis", text: $topic)
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: generateCards) {
                        HStack {
                            if isGenerating {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "rectangle.stack.badge.play")
                            }
                            Text(isGenerating ? "Generating Deck..." : "Create Smart Deck")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(topic.isEmpty || isGenerating)
                    
                } else if currentIndex < flashcards.count {
                    let card = flashcards[currentIndex]
                    
                    Text("Card \(currentIndex + 1) of \(flashcards.count)")
                        .font(.headline)
                        .foregroundColor(Color.theme.textSecondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.theme.cardBackground)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        VStack {
                            Text(isFlipped ? "A" : "Q")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(isFlipped ? Color.theme.accentGreen : Color.theme.accentPurple)
                                .padding(.bottom, 16)
                            
                            Text(isFlipped ? card.back : card.front)
                                .font(.title2)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                    .frame(height: 300)
                    .padding(.horizontal, 32)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0.0, y: 1.0, z: 0.0)
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isFlipped.toggle()
                        }
                    }
                    
                    if isFlipped {
                        HStack(spacing: 16) {
                            Button(action: { nextCard(difficulty: "Hard") }) {
                                Text("Hard")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.theme.accentRed)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { nextCard(difficulty: "Good") }) {
                                Text("Good")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.theme.accentBlue)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { nextCard(difficulty: "Easy") }) {
                                Text("Easy")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.theme.accentGreen)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                    } else {
                        Text("Tap card to flip")
                            .foregroundColor(Color.theme.textSecondary)
                            .padding(.top, 16)
                    }
                } else {
                    Text("Deck Completed!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Your next review is scheduled based on your performance.")
                        .foregroundColor(Color.theme.textSecondary)
                    
                    Button("Study Another Topic") {
                        topic = ""
                        flashcards = []
                        currentIndex = 0
                        isFlipped = false
                    }
                    .padding()
                    .background(Color.theme.cardBackground)
                    .cornerRadius(12)
                    .foregroundColor(.white)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func generateCards() {
        isGenerating = true
        errorMessage = ""
        
        Task {
            do {
                let input = GenerateFlashcardsInput(topic: topic, subject: "General", gradeLevel: "College", numFlashcards: 10)
                let output: GenerateFlashcardsOutput = try await APIClient.shared.runTool(toolId: "generateFlashcards", input: input)
                withAnimation {
                    flashcards = output.flashcards
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isGenerating = false
        }
    }
    
    private func nextCard(difficulty: String) {
        // Here we would save the SM-2 algorithm data to Supabase (spaced_rep_cards table)
        // For now, we just move to the next card
        withAnimation {
            isFlipped = false
            currentIndex += 1
        }
    }
}
