import SwiftUI

struct FocusModeView: View {
    @StateObject private var manager = FocusSessionManager()
    @State private var showingSoundPicker = false
    @State private var showRatingSheet = false
    @State private var subject: String = ""
    @State private var isRecommending = false
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            if SubscriptionManager.shared.currentTier == .free {
                VStack(spacing: 24) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("Focus Mode is locked")
                        .font(.title2).bold().foregroundColor(.white)
                    Text("Upgrade to Pro or Max to access Focus Mode and improve your concentration.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal, 32)
                }
            } else {
                VStack(spacing: 32) {
                // Header
                HStack {
                    Image(systemName: "headphones")
                        .font(.title2)
                        .foregroundColor(Color.theme.accentPurple)
                    Text("Focus Mode")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Timer Ring
                ZStack {
                    Circle()
                        .stroke(Color.theme.cardBackground, lineWidth: 20)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(manager.timeRemaining / manager.totalDuration))
                        .stroke(
                            manager.state == .breakTime ? Color.theme.accentGreen : Color.theme.accentPurple,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: manager.timeRemaining)
                    
                    VStack(spacing: 8) {
                        let minutes = Int(manager.timeRemaining) / 60
                        let seconds = Int(manager.timeRemaining) % 60
                        Text(String(format: "%02d:%02d", minutes, seconds))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(stateLabel)
                            .font(.title3)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                }
                .frame(width: 280, height: 280)
                
                Spacer()
                
                // Current Sound & Volume
                if manager.state != .idle && manager.state != .completed {
                    VStack(spacing: 16) {
                        Button(action: { showingSoundPicker = true }) {
                            HStack {
                                Image(systemName: "speaker.wave.3")
                                Text(manager.currentSound.rawValue)
                                Image(systemName: "chevron.up")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                        }
                        
                        // Volume Slider
                        HStack {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(Color.theme.textSecondary)
                            Slider(value: Binding(
                                get: { AudioEngine.shared.volume },
                                set: { AudioEngine.shared.volume = $0 }
                            ), in: 0...1)
                            .accentColor(Color.theme.accentPurple)
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(Color.theme.textSecondary)
                        }
                        .frame(width: 200)
                    }
                } else {
                    // Pre-session setup
                    VStack(spacing: 16) {
                        TextField("What are you studying? (Optional)", text: $subject)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                        
                        Button(action: recommendSound) {
                            HStack {
                                if isRecommending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isRecommending ? "Finding Best Sound..." : "Ask AI for Best Sound")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                        }
                        .disabled(isRecommending || subject.isEmpty)
                        
                        Button(action: { showingSoundPicker = true }) {
                            HStack {
                                Text("Current Sound: ")
                                    .foregroundColor(Color.theme.textSecondary)
                                Text(manager.currentSound.rawValue)
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.up")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .font(.subheadline)
                        }
                    }
                }
                
                // Controls
                HStack(spacing: 24) {
                    if manager.state == .idle || manager.state == .completed {
                        Button(action: {
                            manager.startSession(workMins: 25, breakMins: 5, sound: manager.currentSound)
                        }) {
                            Text("Start Focus Session")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.theme.primaryGradient)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Button(action: { manager.endSession() }) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(Color.theme.cardBackground)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            if manager.isPaused {
                                manager.resumeSession()
                            } else {
                                manager.pauseSession()
                            }
                        }) {
                            Image(systemName: manager.isPaused ? "play.fill" : "pause.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(Color.theme.primaryGradient)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.bottom, 48)
            }
            }
        }
        .sheet(isPresented: $showingSoundPicker) {
            SoundPickerView(selectedSound: $manager.currentSound)
        }
        .onChange(of: manager.state) { _, newState in
            if newState == .completed {
                showRatingSheet = true
            }
        }
        .sheet(isPresented: $showRatingSheet) {
            FocusRatingView()
        }
    }
    
    private var stateLabel: String {
        switch manager.state {
        case .idle: return "Ready to focus"
        case .working: return "Deep Work"
        case .breakTime: return "Take a Break"
        case .completed: return "Session Complete"
        }
    }
    
    private func recommendSound() {
        guard !subject.isEmpty else { return }
        isRecommending = true
        
        Task {
            do {
                let input = FocusRecommendInput(subject: subject, taskType: nil)
                let output: FocusRecommendOutput = try await APIClient.shared.runTool(
                    toolId: "focusRecommend",
                    input: input
                )
                
                if let sound = FocusSoundType(rawValue: output.recommendedSound) ?? FocusSoundType.allCases.first(where: { $0.id == output.recommendedSound }) {
                    manager.currentSound = sound
                }
            } catch {
                print("Failed to get recommendation: \(error)")
            }
            isRecommending = false
        }
    }
}

struct FocusRecommendInput: Codable {
    let subject: String
    let taskType: String?
}

struct FocusRecommendOutput: Codable {
    let recommendedSound: String
    let reasoning: String
}

struct SoundPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedSound: FocusSoundType
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.mainBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(FocusSoundType.allCases) { sound in
                            Button(action: {
                                selectedSound = sound
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: icon(for: sound))
                                        .font(.system(size: 32))
                                    Text(sound.rawValue)
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(selectedSound == sound ? Color.theme.primaryGradient : LinearGradient(colors: [Color.theme.cardBackground], startPoint: .top, endPoint: .bottom))
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func icon(for sound: FocusSoundType) -> String {
        switch sound {
        case .brownNoise: return "waveform.path.ecg"
        case .pinkNoise: return "brain.head.profile"
        case .whiteNoise: return "shield"
        case .lofi: return "music.note"
        case .rain: return "cloud.rain"
        case .cafe: return "cup.and.saucer"
        }
    }
}

struct FocusRatingView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Text("Session Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("How was your focus?")
                    .font(.title3)
                    .foregroundColor(Color.theme.textSecondary)
                
                HStack(spacing: 24) {
                    RatingButton(emoji: "😴", rating: 1) { save(1) }
                    RatingButton(emoji: "🙂", rating: 2) { save(2) }
                    RatingButton(emoji: "🔥", rating: 3) { save(3) }
                }
                
                Spacer()
            }
            .padding(.top, 64)
        }
    }
    
    private func save(_ rating: Int) {
        // TODO: Save rating to focus_sessions
        presentationMode.wrappedValue.dismiss()
    }
}

struct RatingButton: View {
    let emoji: String
    let rating: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 64))
                .padding()
                .background(Color.theme.cardBackground)
                .clipShape(Circle())
        }
    }
}
