import SwiftUI

struct AppGeneratorView: View {
    let displayName: String
    
    @State private var prompt = ""
    @State private var htmlCode = ""
    @State private var isGenerating = false
    @State private var errorMessage = ""
    @State private var showPreview = false
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mini App Generator")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.theme.textPrimary)
                    Text("Describe an app, and Apple Intelligence will code and render it instantly.")
                        .font(.body)
                        .foregroundColor(Color.theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.top, 16)
                
                if !showPreview {
                    // Input Form
                    VStack(alignment: .leading, spacing: 16) {
                        Text("App Idea")
                            .font(.headline)
                            .foregroundColor(Color.theme.textPrimary)
                        
                        TextEditor(text: $prompt)
                            .frame(height: 150)
                            .padding(8)
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
                            guard !prompt.isEmpty else { return }
                            isGenerating = true
                            errorMessage = ""
                            
                            Task {
                                do {
                                    let generatedHtml = try await AIModelService.shared.generateMiniApp(prompt: prompt)
                                    await MainActor.run {
                                        self.htmlCode = generatedHtml
                                        self.isGenerating = false
                                        self.showPreview = true
                                    }
                                } catch {
                                    await MainActor.run {
                                        self.errorMessage = "Generation failed: \\(error.localizedDescription)"
                                        self.isGenerating = false
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isGenerating {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Generate App")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color.theme.accentCyan, Color(red: 14/255, green: 165/255, blue: 233/255)], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(prompt.isEmpty || isGenerating)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.theme.cardBackground.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 40)
                    
                    Spacer()
                } else {
                    // Preview Area
                    VStack(spacing: 0) {
                        HStack {
                            Text("Live Preview")
                                .font(.headline)
                                .foregroundColor(Color.theme.textPrimary)
                            Spacer()
                            Button("Edit Prompt") {
                                showPreview = false
                            }
                            .font(.subheadline)
                            .foregroundColor(Color.theme.accentCyan)
                        }
                        .padding()
                        .background(Color.theme.sidebarBackground)
                        
                        HTMLWebView(htmlContent: htmlCode)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.white) // Most generated HTML expects a white background by default unless specifically styled for dark mode
                    }
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
