import SwiftUI

struct MVPlannerInput: Codable {
    let subject: String
    let examDate: String
    let currentGrade: String
    let targetGrade: String
    let groundingContext: String?
}

struct MVStudySession: Codable, Hashable {
    let day: String
    let topic: String
    let durationMinutes: Int
    let focus: String
}

struct MVPlannerOutput: Codable {
    let plan: [MVStudySession]
    let advice: String
}

struct MVPlannerView: View {
    @State private var subject = ""
    @State private var examDate = Date()
    @State private var currentGrade = ""
    @State private var targetGrade = ""
    
    @State private var plan: [MVStudySession] = []
    @State private var advice = ""
    @State private var isGenerating = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if plan.isEmpty {
                    Text("Get the absolute minimum viable study plan needed to reach your target grade. No fluff, just high-yield topics.")
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        TextField("Subject (e.g. Organic Chemistry)", text: $subject)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        DatePicker("Exam Date", selection: $examDate, displayedComponents: .date)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 16) {
                            TextField("Current Grade (e.g. C)", text: $currentGrade)
                                .padding()
                                .background(Color.theme.cardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            
                            TextField("Target Grade (e.g. A)", text: $targetGrade)
                                .padding()
                                .background(Color.theme.cardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(Color.theme.accentRed)
                    }
                    
                    Button(action: generatePlan) {
                        HStack {
                            if isGenerating {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "calendar.badge.clock")
                            }
                            Text(isGenerating ? "Building Plan..." : "Generate Minimum Viable Plan")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(subject.isEmpty || currentGrade.isEmpty || targetGrade.isEmpty || isGenerating)
                    
                } else {
                    Button("Start Over") {
                        withAnimation {
                            plan = []
                            advice = ""
                        }
                    }
                    
                    Text("Expert Advice")
                        .font(.headline)
                        .foregroundColor(Color.theme.accentBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Text(advice)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    Text("Your MV Study Plan")
                        .font(.headline)
                        .foregroundColor(Color.theme.accentPurple)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    ForEach(plan, id: \.self) { session in
                        HStack(alignment: .top, spacing: 16) {
                            VStack {
                                Text(session.day)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.theme.textSecondary)
                                Text("\(session.durationMinutes)m")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .frame(width: 60)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.topic)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(session.focus)
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private func generatePlan() {
        isGenerating = true
        errorMessage = ""
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: examDate)
        
        Task {
            do {
                let input = MVPlannerInput(subject: subject, examDate: dateString, currentGrade: currentGrade, targetGrade: targetGrade, groundingContext: nil)
                let output: MVPlannerOutput = try await StudyToolService.shared.runTool(tool: .mvPlanner, input: input)
                withAnimation {
                    plan = output.plan
                    advice = output.advice
                }
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
            }
            isGenerating = false
        }
    }
}
