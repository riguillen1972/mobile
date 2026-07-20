import SwiftUI

struct CrossSubjectInput: Codable {
    let topic: String
    let secondarySubject: String?
    let groundingContext: String?
}

struct CrossSubjectOutput: Codable {
    let connection: String
    let insight: String
}

struct CrossSubjectView: View {
    @State private var topic = ""
    @State private var secondarySubject = ""
    @State private var connection = ""
    @State private var insight = ""
    
    @State private var isConnecting = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if connection.isEmpty {
                    Text("The best ideas happen at the intersection of fields. Connect your topic to a completely different subject.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        TextField("What are you studying? (e.g. Mitochondria)", text: $topic)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        TextField("Optional: Subject to connect it to (e.g. Economics)", text: $secondarySubject)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: connect) {
                        HStack {
                            if isConnecting {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "link")
                            }
                            Text(isConnecting ? "Finding Connections..." : "Cross-Pollinate")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(topic.isEmpty || isConnecting)
                    
                } else {
                    Button("Start Over") {
                        withAnimation {
                            connection = ""
                            insight = ""
                            topic = ""
                            secondarySubject = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("The Connection")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentBlue)
                        
                        Text(connection)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                        
                        Divider().background(Color.gray)
                        
                        Text("Mind-Expanding Insight")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentPurple)
                        
                        Text(insight)
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
    
    private func connect() {
        isConnecting = true
        errorMessage = ""
        
        Task {
            do {
                let input = CrossSubjectInput(topic: topic, secondarySubject: secondarySubject.isEmpty ? nil : secondarySubject, groundingContext: nil)
                let output: CrossSubjectOutput = try await StudyToolService.shared.runTool(tool: .crossSubject, input: input)
                withAnimation {
                    connection = output.connection
                    insight = output.insight
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isConnecting = false
        }
    }
}
