import SwiftUI

struct BibleVerseView: View {
    let displayName: String
    
    @State private var topic = ""
    @State private var verse: BibleVerse? = nil
    @State private var isGenerating = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bible Verses")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.theme.textPrimary)
                        Text("Find a comforting verse for whatever you're going through.")
                            .font(.body)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    .padding(.top, 16)
                    
                    // Input Form
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.theme.accentBlue.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.theme.accentBlue, lineWidth: 1)
                                    )
                                Image(systemName: "book")
                                    .foregroundColor(Color.theme.accentBlue)
                                    .font(.system(size: 24, weight: .bold))
                            }
                            Text("What's on your mind?")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)
                        }
                        
                        TextField("e.g. I am feeling anxious about my upcoming exam", text: $topic)
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
                            verse = nil
                            
                            Task {
                                do {
                                    let newVerse = try await AIModelService.shared.generateBibleVerse(topic: topic)
                                    await MainActor.run {
                                        self.verse = newVerse
                                        self.isGenerating = false
                                    }
                                } catch {
                                    await MainActor.run {
                                        self.errorMessage = "Failed to find verse: \\(error.localizedDescription)"
                                        self.isGenerating = false
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isGenerating {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Find Verse")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color.theme.accentBlue, Color(red: 59/255, green: 130/255, blue: 246/255)], startPoint: .leading, endPoint: .trailing)
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
                    
                    // Output
                    if let verse = verse {
                        VStack(spacing: 24) {
                            Text(verse.reference)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)
                            
                            Text("\\\"\\(verse.text)\\\"")
                                .font(.title3)
                                .fontWeight(.medium)
                                .italic()
                                .foregroundColor(Color.theme.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Why this verse?")
                                    .font(.headline)
                                    .foregroundColor(Color.theme.textSecondary)
                                Text(verse.explanation)
                                    .font(.body)
                                    .foregroundColor(Color.theme.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.theme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.theme.accentBlue.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.theme.accentBlue.opacity(0.1), radius: 20, x: 0, y: 10)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}
