import SwiftUI

struct FlashcardsView: View {
    let displayName: String
    
    @State private var topic = ""
    @State private var cards: [Flashcard] = []
    @State private var isGenerating = false
    @State private var currentIndex = 0
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Flashcards")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.theme.textPrimary)
                        Text("Generate AI flashcards to test your knowledge.")
                            .font(.body)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    .padding(.top, 16)
                    
                    // Input Form
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.theme.accentPurple.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.theme.accentPurple, lineWidth: 1)
                                    )
                                Image(systemName: "rectangle.stack")
                                    .foregroundColor(Color.theme.accentPurple)
                                    .font(.system(size: 24, weight: .bold))
                            }
                            Text("Generate a Deck")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)
                        }
                        
                        TextField("What do you want to study? (e.g., Cellular Biology)", text: $topic)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(Color.theme.textPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                        
                        Button(action: {
                            guard !topic.isEmpty else { return }
                            isGenerating = true
                            errorMessage = ""
                            cards.removeAll()
                            currentIndex = 0
                            
                            Task {
                                do {
                                    let newCards = try await AIModelService.shared.generateFlashcards(topic: topic)
                                    await MainActor.run {
                                        cards = newCards
                                        isGenerating = false
                                    }
                                    try? await ProgressService.shared.logActivity(type: "Flashcards", durationMinutes: 5, score: nil)
                                } catch {
                                    await MainActor.run {
                                        errorMessage = "Failed to generate flashcards: \\(error.localizedDescription)"
                                        isGenerating = false
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isGenerating {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Generate Flashcards")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color.theme.accentPurple, Color(red: 168/255, green: 85/255, blue: 247/255)], startPoint: .leading, endPoint: .trailing)
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
                    
                    // Cards Area
                    if !cards.isEmpty {
                        VStack(spacing: 24) {
                            Text("Card \\(currentIndex + 1) of \\(cards.count)")
                                .font(.headline)
                                .foregroundColor(Color.theme.textSecondary)
                            
                            FlashcardView(card: cards[currentIndex])
                                .frame(height: 300)
                            
                            HStack(spacing: 32) {
                                Button(action: {
                                    if currentIndex > 0 {
                                        withAnimation { currentIndex -= 1 }
                                    }
                                }) {
                                    Image(systemName: "chevron.left.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(currentIndex > 0 ? Color.theme.accentPurple : Color.gray)
                                }
                                .disabled(currentIndex == 0)
                                
                                Button(action: {
                                    if currentIndex < cards.count - 1 {
                                        withAnimation { currentIndex += 1 }
                                    }
                                }) {
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(currentIndex < cards.count - 1 ? Color.theme.accentPurple : Color.gray)
                                }
                                .disabled(currentIndex == cards.count - 1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}
