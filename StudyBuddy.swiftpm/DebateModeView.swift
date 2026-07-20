import SwiftUI

struct DebateModeInput: Codable {
    let topic: String
    let userArgument: String
    let groundingContext: String?
}

struct DebateModeOutput: Codable {
    let counterArgument: String
    let feedback: String
}

struct DebateMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let feedback: String?
}

struct DebateModeView: View {
    @State private var topic = ""
    @State private var argument = ""
    @State private var messages: [DebateMessage] = []
    
    @State private var isDebating = false
    @State private var errorMessage = ""
    @State private var isTopicSet = false
    
    var body: some View {
        VStack(spacing: 0) {
            if !isTopicSet {
                VStack(spacing: 24) {
                    Text("Defend your knowledge. Enter a topic, and the AI will try to poke holes in your argument.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    TextField("Debate Topic (e.g. AI is dangerous)", text: $topic)
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    Button("Start Debate") {
                        isTopicSet = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.primaryGradient)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(topic.isEmpty)
                    
                    Spacer()
                }
                .padding(.top, 24)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Topic: \(topic)")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentBlue)
                            .padding(.top)
                        
                        ForEach(messages) { msg in
                            HStack {
                                if msg.isUser { Spacer() }
                                
                                VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 8) {
                                    Text(msg.text)
                                        .foregroundColor(msg.isUser ? .white : .black)
                                    
                                    if let feedback = msg.feedback {
                                        Text("Feedback: \(feedback)")
                                            .font(.caption)
                                            .foregroundColor(Color.theme.accentOrange)
                                            .padding(.top, 4)
                                    }
                                }
                                .padding()
                                .background(msg.isUser ? Color.theme.accentBlue : Color.white)
                                .cornerRadius(16)
                                .frame(maxWidth: 280, alignment: msg.isUser ? .trailing : .leading)
                                
                                if !msg.isUser { Spacer() }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage).foregroundColor(Color.theme.accentRed).padding()
                }
                
                HStack {
                    TextField("Your argument...", text: $argument)
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    
                    Button(action: sendArgument) {
                        if isDebating {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(12)
                        } else {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.theme.primaryGradient)
                                .clipShape(Circle())
                        }
                    }
                    .disabled(argument.isEmpty || isDebating)
                }
                .padding()
            }
        }
        .background(Color.theme.mainBackground.ignoresSafeArea())
    }
    
    private func sendArgument() {
        let userArg = argument
        argument = ""
        messages.append(DebateMessage(isUser: true, text: userArg, feedback: nil))
        
        isDebating = true
        errorMessage = ""
        
        Task {
            do {
                let input = DebateModeInput(topic: topic, userArgument: userArg, groundingContext: nil)
                let output: DebateModeOutput = try await StudyToolService.shared.runTool(tool: .debateMode, input: input)
                withAnimation {
                    messages.append(DebateMessage(isUser: false, text: output.counterArgument, feedback: output.feedback))
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isDebating = false
        }
    }
}
