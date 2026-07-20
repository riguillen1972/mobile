import SwiftUI

struct DeepUnderstandingInput: Codable {
    let topic: String
    let groundingContext: String?
}

struct DeepUnderstandingOutput: Codable {
    let corePrinciple: String
    let whyItMatters: String
    let commonMisconceptions: [String]
}

struct DeepUnderstandingView: View {
    @State private var topic = ""
    @State private var corePrinciple = ""
    @State private var whyItMatters = ""
    @State private var commonMisconceptions: [String] = []
    
    @State private var isAnalyzing = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if corePrinciple.isEmpty {
                    Text("Move past rote memorization. Understand the 'Why' behind any concept.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    TextField("Concept (e.g. Entropy, Supply and Demand)", text: $topic)
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: analyze) {
                        HStack {
                            if isAnalyzing {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "brain.head.profile")
                            }
                            Text(isAnalyzing ? "Unpacking..." : "Get Deep Understanding")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(topic.isEmpty || isAnalyzing)
                    
                } else {
                    Button("Start Over") {
                        withAnimation {
                            corePrinciple = ""
                            whyItMatters = ""
                            commonMisconceptions = []
                            topic = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Core First Principle")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentBlue)
                        
                        Text(corePrinciple)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                        
                        Divider().background(Color.gray)
                        
                        Text("Why It Matters (Real World)")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentGreen)
                        
                        Text(whyItMatters)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                        
                        Divider().background(Color.gray)
                        
                        Text("Common Misconceptions")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentRed)
                        
                        ForEach(commonMisconceptions, id: \.self) { misconception in
                            HStack(alignment: .top) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.theme.accentRed)
                                Text(misconception)
                                    .foregroundColor(.white)
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
    
    private func analyze() {
        isAnalyzing = true
        errorMessage = ""
        
        Task {
            do {
                let input = DeepUnderstandingInput(topic: topic, groundingContext: nil)
                let output: DeepUnderstandingOutput = try await StudyToolService.shared.runTool(tool: .deepUnderstanding, input: input)
                withAnimation {
                    corePrinciple = output.corePrinciple
                    whyItMatters = output.whyItMatters
                    commonMisconceptions = output.commonMisconceptions
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isAnalyzing = false
        }
    }
}
