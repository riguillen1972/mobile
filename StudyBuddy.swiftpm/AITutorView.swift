import SwiftUI

struct AITutorView: View {
    let displayName: String
    
    @EnvironmentObject var authState: AuthState
    @ObservedObject var subManager = SubscriptionManager.shared
    
    @State private var inputText = ""
    @State private var tutorMode = 0 // 0 = Help Mode, 1 = Research Mode
    @State private var selectedModel = ""
    @State private var messages: [ChatMessage] = []
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back, \(displayName)!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.theme.textPrimary)
                    
                    Text("Ready to learn something new? Ask the AI Tutor anything.")
                        .font(.body)
                        .foregroundColor(Color.theme.textSecondary)
                }
                .padding(.top, 16)
                
                // AI Tutor Main Card
                VStack(alignment: .leading, spacing: 24) {
                    // Card Header
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.primaryGradient)
                                .frame(width: 48, height: 48)
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Tutor")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)
                            Text("Ask a question or describe a concept you want to understand better.")
                                .font(.subheadline)
                                .foregroundColor(Color.theme.textSecondary)
                        }
                    }
                    
                    // Chat Messages Area
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                if messages.isEmpty {
                                    HStack(spacing: 12) {
                                        Image(systemName: "bubble.left")
                                            .foregroundColor(Color.theme.textSecondary)
                                            .font(.title2)
                                        Text("Your conversation will appear here.")
                                            .foregroundColor(Color.theme.textSecondary)
                                            .font(.body)
                                        Spacer()
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                } else {
                                    ForEach(messages) { message in
                                        AIChatMessageView(message: message)
                                            .id(message.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(height: 300)
                        .padding(.vertical, 8)
                        .onChange(of: messages) {
                            if let last = messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input Field Area
                    HStack {
                        TextField("e.g., Explain the theory of relativity", text: $inputText)
                            .foregroundColor(Color.theme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        
                        Button(action: {
                            guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            let newMsg = ChatMessage(role: .user, content: inputText)
                            messages.append(newMsg)
                            inputText = ""
                            
                            // Use Anthropic API
                            Task {
                                do {
                                    let responseText = try await AIModelService.shared.sendMessage(messages: messages, tutorMode: tutorMode, model: selectedModel)
                                    await MainActor.run {
                                        let aiMsg = ChatMessage(role: .assistant, content: responseText)
                                        messages.append(aiMsg)
                                    }
                                    
                                    // Log activity
                                    try? await ProgressService.shared.logActivity(type: "AI Tutor Session", durationMinutes: 2, score: nil)
                                } catch {
                                    await MainActor.run {
                                        let errorMsg = ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)")
                                        messages.append(errorMsg)
                                    }
                                }
                            }
                        }) {
                            Text("Ask")
                                .fontWeight(.bold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.theme.primaryGradient)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.trailing, 8)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    
                    // Configuration Options
                    HStack(alignment: .top, spacing: 24) {
                        // Tutor Mode
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tutor Mode")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.theme.textSecondary)
                            
                            HStack(spacing: 0) {
                                Button(action: { tutorMode = 0 }) {
                                    Text("Help Mode")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(tutorMode == 0 ? Color.theme.accentCyan : Color.clear)
                                        .foregroundColor(tutorMode == 0 ? .white : Color.theme.textSecondary)
                                }
                                
                                Button(action: { tutorMode = 1 }) {
                                    Text("Research Mode")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(tutorMode == 1 ? Color.theme.accentCyan : Color.clear)
                                        .foregroundColor(tutorMode == 1 ? .white : Color.theme.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .frame(maxWidth: .infinity)
                        
                        // AI Model
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Model")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.theme.textSecondary)
                            
                            Menu {
                                if subManager.currentTier == .free {
                                    Button("Gemini 2.5 Flash-Lite", action: { selectedModel = "googleai/gemini-2.5-flash-lite" })
                                }
                                
                                if subManager.currentTier == .pro {
                                    Button("Gemini 2.5 Flash", action: { selectedModel = "googleai/gemini-2.5-flash" })
                                    Button("Gemini 2.5 Pro", action: { selectedModel = "googleai/gemini-2.5-pro" })
                                }
                                
                                if subManager.currentTier == .max {
                                    Button("Gemini 2.5 Flash", action: { selectedModel = "googleai/gemini-2.5-flash" })
                                    Button("Claude Haiku 4.5", action: { selectedModel = "claude-haiku-4-5" })
                                }
                            } label: {
                                HStack {
                                    Text(modelDisplayName(for: selectedModel))
                                        .foregroundColor(Color.theme.textPrimary)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Color.theme.textSecondary)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
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
                
                // Bottom Cards
                HStack(spacing: 24) {
                    DashboardCard(
                        iconName: "viewfinder",
                        title: "Scan Homework",
                        subtitle: "Upload and solve",
                        accentColor: Color.theme.accentPurple,
                        action: {}
                    )
                    
                    DashboardCard(
                        iconName: "list.bullet.clipboard",
                        title: "Quiz Generator",
                        subtitle: "Test your knowledge",
                        accentColor: Color.theme.accentCyan,
                        action: {}
                    )
                    
                    DashboardCard(
                        iconName: "doc.text",
                        title: "Summarizer",
                        subtitle: "Quick summaries",
                        accentColor: Color.theme.accentRed,
                        action: {}
                    )
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 40)
            .onAppear {
                setDefaultModel()
            }
            .onChange(of: authState.userTier) {
                setDefaultModel()
            }
        }
    }
}
    
    private func setDefaultModel() {
        switch subManager.currentTier {
        case .free: 
            selectedModel = "googleai/gemini-2.5-flash-lite"
        case .pro: 
            if selectedModel != "googleai/gemini-2.5-flash" && selectedModel != "googleai/gemini-2.5-pro" {
                selectedModel = "googleai/gemini-2.5-flash"
            }
        case .max: 
            if selectedModel != "googleai/gemini-2.5-flash" && selectedModel != "claude-haiku-4-5" {
                selectedModel = "googleai/gemini-2.5-flash"
            }
        }
    }
    
    private func modelDisplayName(for id: String) -> String {
        switch id {
        case "googleai/gemini-2.5-flash-lite": return "Gemini 2.5 Flash-Lite"
        case "googleai/gemini-2.5-flash": return "Gemini 2.5 Flash"
        case "googleai/gemini-2.5-pro": return "Gemini 2.5 Pro"
        case "claude-haiku-4-5": return "Claude Haiku 4.5"
        default: return "Select Model"
        }
    }
}
