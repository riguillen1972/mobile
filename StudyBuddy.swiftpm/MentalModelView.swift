import SwiftUI

struct MentalModelInput: Codable {
    let topic: String
    let groundingContext: String?
}

struct MentalModelOutput: Codable {
    let mentalModelName: String
    let description: String
    let application: String
}

struct MentalModelView: View {
    @State private var topic = ""
    @State private var modelName = ""
    @State private var modelDescription = ""
    @State private var application = ""
    
    @State private var isGenerating = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if modelName.isEmpty {
                    Text("Apply frameworks like First Principles, Inversion, or Pareto Principle to your studies.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    TextField("What are you studying?", text: $topic)
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: generate) {
                        HStack {
                            if isGenerating {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "square.stack.3d.up")
                            }
                            Text(isGenerating ? "Finding Framework..." : "Build Mental Model")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(topic.isEmpty || isGenerating)
                    
                } else {
                    Button("Start Over") {
                        withAnimation {
                            modelName = ""
                            modelDescription = ""
                            application = ""
                            topic = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(modelName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.accentPurple)
                        
                        Text("What is it?")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentBlue)
                        
                        Text(modelDescription)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                        
                        Divider().background(Color.gray)
                        
                        Text("How to apply it to \(topic)")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentGreen)
                        
                        Text(application)
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
    
    private func generate() {
        isGenerating = true
        errorMessage = ""
        
        Task {
            do {
                let input = MentalModelInput(topic: topic, groundingContext: nil)
                let output: MentalModelOutput = try await StudyToolService.shared.runTool(tool: .mentalModel, input: input)
                withAnimation {
                    modelName = output.mentalModelName
                    modelDescription = output.description
                    application = output.application
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isGenerating = false
        }
    }
}
