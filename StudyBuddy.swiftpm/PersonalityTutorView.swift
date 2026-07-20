import SwiftUI

struct PersonalityTutorInput: Codable {
    let topic: String
    let personality: String
    let groundingContext: String?
}

struct PersonalityTutorOutput: Codable {
    let explanation: String
}

struct PersonalityTutorView: View {
    @State private var topic = ""
    @State private var personality = "yoda"
    @State private var explanation = ""
    
    @State private var isTeaching = false
    @State private var errorMessage = ""
    
    let personalities = ["pirate", "yoda", "shakespeare", "drill_sergeant", "chill_surfer"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if explanation.isEmpty {
                    Text("Bored of standard textbook explanations? Let a fun persona teach you.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        TextField("What do you want to learn?", text: $topic)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        Picker("Personality", selection: $personality) {
                            ForEach(personalities, id: \.self) { p in
                                Text(p.replacingOccurrences(of: "_", with: " ").capitalized).tag(p)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: teach) {
                        HStack {
                            if isTeaching {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "person.text.rectangle")
                            }
                            Text(isTeaching ? "Preparing Lesson..." : "Teach Me")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(topic.isEmpty || isTeaching)
                    
                } else {
                    Button("Start Over") {
                        withAnimation {
                            explanation = ""
                            topic = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Tutor: \(personality.replacingOccurrences(of: "_", with: " ").capitalized)")
                                .font(.headline)
                                .foregroundColor(Color.theme.accentOrange)
                            Spacer()
                        }
                        
                        Text(explanation)
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
    
    private func teach() {
        isTeaching = true
        errorMessage = ""
        
        Task {
            do {
                let input = PersonalityTutorInput(topic: topic, personality: personality, groundingContext: nil)
                let output: PersonalityTutorOutput = try await StudyToolService.shared.runTool(tool: .personalityTutor, input: input)
                withAnimation {
                    explanation = output.explanation
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isTeaching = false
        }
    }
}
