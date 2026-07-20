import SwiftUI

struct SmartSummarizerInput: Codable {
    let content: String
    let groundingContext: String?
}

struct SmartSummarizerOutput: Codable {
    let summary: [String]
    let keyTerms: [String]
}

struct SmartSummarizerView: View {
    @State private var content = ""
    @State private var summary: [String] = []
    @State private var keyTerms: [String] = []
    
    @State private var isSummarizing = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if summary.isEmpty {
                    Text("Paste your messy notes, chapter text, or lecture transcript. We'll strip the fluff and give you testable concepts.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    TextEditor(text: $content)
                        .frame(height: 250)
                        .padding(8)
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: summarize) {
                        HStack {
                            if isSummarizing {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "text.alignleft")
                            }
                            Text(isSummarizing ? "Extracting..." : "Smart Summarize")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(content.isEmpty || isSummarizing)
                    
                } else {
                    Button("Start Over") {
                        withAnimation {
                            summary = []
                            keyTerms = []
                            content = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Testable Concepts")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentBlue)
                        
                        ForEach(summary, id: \.self) { point in
                            HStack(alignment: .top) {
                                Text("•")
                                    .foregroundColor(Color.theme.accentBlue)
                                Text(point)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Divider().background(Color.gray)
                        
                        Text("Key Terms to Know")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentPurple)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                            ForEach(keyTerms, id: \.self) { term in
                                Text(term)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
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
    
    private func summarize() {
        isSummarizing = true
        errorMessage = ""
        
        Task {
            do {
                let input = SmartSummarizerInput(content: content, groundingContext: nil)
                let output: SmartSummarizerOutput = try await StudyToolService.shared.runTool(tool: .smartSummarizer, input: input)
                withAnimation {
                    summary = output.summary
                    keyTerms = output.keyTerms
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isSummarizing = false
        }
    }
}
