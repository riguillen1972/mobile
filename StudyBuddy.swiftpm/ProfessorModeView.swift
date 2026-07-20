import SwiftUI

struct ProfessorModeInput: Codable {
    let topic: String
    let question: String
    let groundingContext: String?
}

struct ProfessorModeOutput: Codable {
    let answer: String
    let furtherReading: [String]
}

struct ProfessorModeView: View {
    @State private var topic = ""
    @State private var question = ""
    @State private var answer = ""
    @State private var furtherReading: [String] = []
    
    @State private var isAsking = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if answer.isEmpty {
                    Text("Have a highly specific, advanced question? Get a rigorous, academic answer from Professor Mode.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        TextField("Topic (e.g. Molecular Biology)", text: $topic)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $question)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                Text("Ask your advanced question...")
                                    .foregroundColor(Color.theme.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .opacity(question.isEmpty ? 1 : 0),
                                alignment: .topLeading
                            )
                    }
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: askProfessor) {
                        HStack {
                            if isAsking {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "graduationcap.fill")
                            }
                            Text(isAsking ? "Consulting..." : "Ask the Professor")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(topic.isEmpty || question.isEmpty || isAsking)
                    
                } else {
                    Button("Ask Another Question") {
                        withAnimation {
                            answer = ""
                            furtherReading = []
                            question = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Professor's Answer")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentPurple)
                        
                        Text(answer)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                        
                        if !furtherReading.isEmpty {
                            Divider().background(Color.gray)
                            
                            Text("Recommended Reading")
                                .font(.headline)
                                .foregroundColor(Color.theme.accentBlue)
                            
                            ForEach(furtherReading, id: \.self) { reading in
                                HStack(alignment: .top) {
                                    Image(systemName: "book.circle.fill")
                                        .foregroundColor(Color.theme.accentBlue)
                                    Text(reading)
                                        .foregroundColor(.white)
                                }
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
    
    private func askProfessor() {
        isAsking = true
        errorMessage = ""
        
        Task {
            do {
                let input = ProfessorModeInput(topic: topic, question: question, groundingContext: nil)
                let output: ProfessorModeOutput = try await StudyToolService.shared.runTool(tool: .professorMode, input: input)
                withAnimation {
                    answer = output.answer
                    furtherReading = output.furtherReading
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isAsking = false
        }
    }
}
