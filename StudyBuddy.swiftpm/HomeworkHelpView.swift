import SwiftUI

struct HomeworkHelpView: View {
    let displayName: String
    
    @State private var questionText = ""
    @State private var selectedSubject = "Math"
    @State private var isSolving = false
    @State private var answerText = ""
    
    let subjects = ["Math", "Science", "History", "Literature", "Computer Science", "Other"]
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Homework Help")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.theme.textPrimary)
                    
                    Text("Stuck on a problem? Let's break it down together.")
                        .font(.body)
                        .foregroundColor(Color.theme.textSecondary)
                }
                .padding(.top, 16)
                
                // Homework Form Card
                VStack(alignment: .leading, spacing: 24) {
                    // Card Header
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.accentOrange.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.theme.accentOrange, lineWidth: 1)
                                )
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(Color.theme.accentOrange)
                                .font(.system(size: 24, weight: .bold))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ask a Question")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)
                        }
                    }
                    
                    // Subject Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.theme.textSecondary)
                        
                        Menu {
                            ForEach(subjects, id: \.self) { subject in
                                Button(subject, action: { selectedSubject = subject })
                            }
                        } label: {
                            HStack {
                                Text(selectedSubject)
                                    .foregroundColor(Color.theme.textPrimary)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.theme.textSecondary)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Input Text Editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.theme.textSecondary)
                        
                        ZStack(alignment: .topLeading) {
                            if questionText.isEmpty {
                                Text("Type your homework question here...")
                                    .foregroundColor(Color.theme.textSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                            }
                            TextEditor(text: $questionText)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(Color.theme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .frame(minHeight: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Solve Action Button
                    Button(action: {
                        guard !questionText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        isSolving = true
                        
                        // Call Anthropic API
                        Task {
                            do {
                                let messages = [ChatMessage(role: .user, content: "Please help me solve this \(selectedSubject) problem and explain the steps:\n\n\(questionText)")]
                                let response = try await AIModelService.shared.sendMessage(messages: messages, tutorMode: 0)
                                await MainActor.run {
                                    isSolving = false
                                    answerText = response
                                }
                            } catch {
                                await MainActor.run {
                                    isSolving = false
                                    answerText = "Error: \(error.localizedDescription)"
                                }
                            }
                        }
                    }) {
                        HStack {
                            if isSolving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Get Help")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color.theme.accentOrange, Color(red: 234/255, green: 88/255, blue: 12/255)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(questionText.trimmingCharacters(in: .whitespaces).isEmpty || isSolving)
                    .opacity(questionText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                    
                    // Output Section
                    if !answerText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Solution & Explanation")
                                .font(.headline)
                                .foregroundColor(Color.theme.textPrimary)
                            
                            Text(answerText)
                                .font(.body)
                                .foregroundColor(Color.theme.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.theme.accentOrange.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.theme.accentOrange.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 25/255, green: 35/255, blue: 60/255).opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
}
