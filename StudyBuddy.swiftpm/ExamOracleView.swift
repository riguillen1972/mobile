import SwiftUI

struct ExamOracleInput: Codable {
    let materials: String
    let groundingContext: String?
}

struct ExamOraclePrediction: Codable, Hashable {
    let question: String
    let likelihood: String
    let explanation: String
}

struct ExamOracleOutput: Codable {
    let predictions: [ExamOraclePrediction]
}

struct ExamOracleView: View {
    @State private var materials = ""
    @State private var predictions: [ExamOraclePrediction] = []
    @State private var isPredicting = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if predictions.isEmpty {
                    Text("Paste your syllabus or study notes below, and the Oracle will predict the most likely exam questions.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    TextEditor(text: $materials)
                        .frame(height: 200)
                        .padding(8)
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: predict) {
                        HStack {
                            if isPredicting {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "crystalcube")
                            }
                            Text(isPredicting ? "Predicting..." : "Reveal Questions")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(materials.isEmpty || isPredicting)
                } else {
                    Button("Start Over") {
                        withAnimation {
                            predictions = []
                            materials = ""
                        }
                    }
                    .padding()
                    
                    ForEach(predictions, id: \.self) { pred in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(pred.likelihood == "High" ? "🔥 High Likelihood" : "Medium Likelihood")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(pred.likelihood == "High" ? Color.theme.accentOrange : Color.theme.accentBlue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                Spacer()
                            }
                            
                            Text(pred.question)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(pred.explanation)
                                .font(.subheadline)
                                .foregroundColor(Color.theme.textSecondary)
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
    
    private func predict() {
        isPredicting = true
        errorMessage = ""
        
        Task {
            do {
                let input = ExamOracleInput(materials: materials, groundingContext: nil)
                let output: ExamOracleOutput = try await StudyToolService.shared.runTool(tool: .examOracle, input: input)
                withAnimation {
                    predictions = output.predictions
                }
            } catch {
                errorMessage = "Failed to predict: \(error.localizedDescription)"
            }
            isPredicting = false
        }
    }
}
