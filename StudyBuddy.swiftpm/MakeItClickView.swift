import SwiftUI

struct MakeItClickInput: Codable {
    let concept: String
    let userStruggle: String
    let groundingContext: String?
}

struct MakeItClickOutput: Codable {
    let ahaMoment: String
    let visualization: String
}

struct MakeItClickView: View {
    @State private var concept = ""
    @State private var struggle = ""
    @State private var ahaMoment = ""
    @State private var visualization = ""
    
    @State private var isGenerating = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if ahaMoment.isEmpty {
                    Text("Struggling to understand something? Tell us what's confusing, and we'll give you an 'Aha!' moment.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        TextField("Concept (e.g. Calculus limits)", text: $concept)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        TextField("What's confusing about it?", text: $struggle)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: generate) {
                        HStack {
                            if isGenerating {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "lightbulb.max")
                            }
                            Text(isGenerating ? "Thinking..." : "Make It Click")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(concept.isEmpty || struggle.isEmpty || isGenerating)
                    
                } else {
                    Button("Start Over") {
                        withAnimation {
                            ahaMoment = ""
                            visualization = ""
                            concept = ""
                            struggle = ""
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("💡 The Aha! Moment")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentGreen)
                        
                        Text(ahaMoment)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                        
                        Divider().background(Color.gray)
                        
                        Text("👁️ Visualize It")
                            .font(.headline)
                            .foregroundColor(Color.theme.accentBlue)
                        
                        Text(visualization)
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
                let input = MakeItClickInput(concept: concept, userStruggle: struggle, groundingContext: nil)
                let output: MakeItClickOutput = try await StudyToolService.shared.runTool(tool: .makeItClick, input: input)
                withAnimation {
                    ahaMoment = output.ahaMoment
                    visualization = output.visualization
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isGenerating = false
        }
    }
}
