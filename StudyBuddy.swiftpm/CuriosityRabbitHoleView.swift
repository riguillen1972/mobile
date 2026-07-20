import SwiftUI

struct CuriosityInput: Codable {
    let topic: String
    let depth: Int
}

struct CuriosityOutput: Codable {
    let fascinatingFact: String
    let deepDive: String
    let nextRabbitHole: String
}

struct CuriosityRabbitHoleView: View {
    @State private var topic = ""
    @State private var depth = 1
    @State private var outputs: [CuriosityOutput] = []
    
    @State private var isDigging = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if outputs.isEmpty {
                    Text("Go down a Wikipedia-style rabbit hole. Pick a topic and how deep you want to go.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        TextField("Topic (e.g. Black Holes, The Silk Road)", text: $topic)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading) {
                            Text("Depth Level: \(depth)")
                                .foregroundColor(.white)
                            Picker("Depth", selection: $depth) {
                                Text("1: Surface").tag(1)
                                Text("2: Obscure").tag(2)
                                Text("3: Existential").tag(3)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: { dig(topic: topic) }) {
                        HStack {
                            if isDigging {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "hare")
                            }
                            Text(isDigging ? "Digging..." : "Enter the Rabbit Hole")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(topic.isEmpty || isDigging)
                    
                } else {
                    Button("Start Over") {
                        withAnimation {
                            outputs = []
                            topic = ""
                        }
                    }
                    
                    ForEach(Array(outputs.enumerated()), id: \.offset) { index, output in
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Level \(index + 1) Depth")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.accentBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("Fascinating Fact")
                                .font(.headline)
                                .foregroundColor(Color.theme.accentPink)
                            Text(output.fascinatingFact)
                                .foregroundColor(.white)
                            
                            Text("Deep Dive")
                                .font(.headline)
                                .foregroundColor(Color.theme.accentPurple)
                            Text(output.deepDive)
                                .foregroundColor(Color.theme.textSecondary)
                            
                            if index == outputs.count - 1 {
                                Divider().background(Color.gray)
                                Text("Next Rabbit Hole:")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textSecondary)
                                Button(action: { dig(topic: output.nextRabbitHole) }) {
                                    HStack {
                                        Text(output.nextRabbitHole)
                                        Image(systemName: "arrow.right.circle.fill")
                                    }
                                    .foregroundColor(Color.theme.accentGreen)
                                }
                            }
                        }
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private func dig(topic targetTopic: String) {
        isDigging = true
        errorMessage = ""
        
        Task {
            do {
                let input = CuriosityInput(topic: targetTopic, depth: min(outputs.count + 1, 3)) // increase depth each time
                let output: CuriosityOutput = try await StudyToolService.shared.runTool(tool: .curiosityRabbitHole, input: input)
                withAnimation {
                    outputs.append(output)
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isDigging = false
        }
    }
}
