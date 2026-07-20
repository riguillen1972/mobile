import SwiftUI

struct SummarizerView: View {
    let displayName: String
    
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isSummarizing = false
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summarizer")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.theme.textPrimary)
                    
                    Text("Paste any long text, article, or notes to get a quick AI summary.")
                        .font(.body)
                        .foregroundColor(Color.theme.textSecondary)
                }
                .padding(.top, 16)
                
                // Summarizer Main Card
                VStack(alignment: .leading, spacing: 24) {
                    // Card Header
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.accentRed.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.theme.accentRed, lineWidth: 1)
                                )
                            Image(systemName: "doc.text")
                                .foregroundColor(Color.theme.accentRed)
                                .font(.system(size: 24, weight: .bold))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Text to Summarize")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)
                        }
                    }
                    
                    // Input Text Editor
                    ZStack(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text("Paste your text here...")
                                .foregroundColor(Color.theme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        }
                        TextEditor(text: $inputText)
                            .scrollContentBackground(.hidden) // Removes default iOS background
                            .foregroundColor(Color.theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .frame(minHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    
                    // Summarize Action Button
                    Button(action: {
                        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        isSummarizing = true
                        
                        // Call Anthropic API
                        Task {
                            do {
                                let messages = [ChatMessage(role: .user, content: "Please summarize the following text:\\n\\n\\(inputText)")]
                                let summary = try await AIModelService.shared.sendMessage(messages: messages, tutorMode: 0)
                                await MainActor.run {
                                    isSummarizing = false
                                    outputText = summary
                                }
                            } catch {
                                await MainActor.run {
                                    isSummarizing = false
                                    outputText = "Error: \\(error.localizedDescription)"
                                }
                            }
                        }
                    }) {
                        HStack {
                            if isSummarizing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Summarize")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color.theme.accentRed, Color(red: 220/255, green: 38/255, blue: 38/255)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSummarizing)
                    .opacity(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                    
                    // Output Section
                    if !outputText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Summary")
                                .font(.headline)
                                .foregroundColor(Color.theme.textPrimary)
                            
                            Text(outputText)
                                .font(.body)
                                .foregroundColor(Color.theme.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 25/255, green: 35/255, blue: 60/255).opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
}
