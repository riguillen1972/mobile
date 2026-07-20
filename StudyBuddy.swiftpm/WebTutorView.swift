import SwiftUI

struct WebTutorView: View {
    let displayName: String
    
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @State private var topic = ""
    @State private var htmlLesson = ""
    @State private var isGenerating = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            Group {
                if sizeClass == .compact {
                    VStack(spacing: 0) {
                        inputPanel
                            .padding(.bottom, 16)
                        Divider().background(Color.white.opacity(0.1))
                        previewPanel
                    }
                } else {
                    HStack(spacing: 0) {
                        inputPanel
                            .frame(width: 400)
                        Divider().background(Color.white.opacity(0.1))
                        previewPanel
                    }
                }
            }
        }
    }
    
    private var inputPanel: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Web Tutor")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.theme.textPrimary)
                Text("Interactive lessons generated on the fly.")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("What do you want to learn?")
                    .font(.headline)
                    .foregroundColor(Color.theme.textPrimary)
                
                TextField("e.g. How the Solar System works", text: $topic)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(Color.theme.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Button(action: {
                    guard !topic.isEmpty else { return }
                    isGenerating = true
                    errorMessage = ""
                    
                    Task {
                        do {
                            let lesson = try await AIModelService.shared.generateWebTutorLesson(topic: topic)
                            await MainActor.run {
                                self.htmlLesson = lesson
                                self.isGenerating = false
                            }
                        } catch {
                            await MainActor.run {
                                self.errorMessage = "Generation failed: \(error.localizedDescription)"
                                self.isGenerating = false
                            }
                        }
                    }
                }) {
                    HStack {
                        if isGenerating {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Generate Lesson")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.theme.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(topic.isEmpty || isGenerating)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground.opacity(0.5))
            )
            
            if sizeClass != .compact {
                Spacer()
            }
        }
        .padding(32)
    }
    
    private var previewPanel: some View {
        ZStack {
            if htmlLesson.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.system(size: 64))
                        .foregroundColor(Color.theme.textSecondary.opacity(0.5))
                    Text("Your interactive lesson will appear here.")
                        .font(.headline)
                        .foregroundColor(Color.theme.textSecondary)
                }
            } else {
                HTMLWebView(htmlContent: htmlLesson)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }
}
