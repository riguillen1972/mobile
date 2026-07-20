import SwiftUI

enum FocusSessionState {
    case idle
    case working
    case breakTime
    case completed
}

@MainActor
final class FocusSessionManager: ObservableObject {
    @Published var state: FocusSessionState = .idle
    @Published var currentSound: FocusSoundType = .brownNoise {
        didSet {
            if state == .working && !isPaused {
                AudioEngine.shared.play(sound: currentSound)
            }
        }
    }
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 25 * 60 // 25 mins work default
    @Published var workDuration: TimeInterval = 25 * 60
    @Published var breakDuration: TimeInterval = 5 * 60
    @Published var isPaused = false
    
    private var timer: Timer?
    
    func startSession(workMins: Int = 25, breakMins: Int = 5, sound: FocusSoundType) {
        self.workDuration = TimeInterval(workMins * 60)
        self.breakDuration = TimeInterval(breakMins * 60)
        self.totalDuration = self.workDuration
        self.timeRemaining = self.workDuration
        self.currentSound = sound
        self.state = .working
        self.isPaused = false
        
        AudioEngine.shared.play(sound: sound)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    func pauseSession() {
        timer?.invalidate()
        timer = nil
        isPaused = true
        AudioEngine.shared.stop()
    }
    
    func resumeSession() {
        isPaused = false
        AudioEngine.shared.play(sound: currentSound)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    func endSession() {
        timer?.invalidate()
        timer = nil
        isPaused = false
        AudioEngine.shared.stop()
        state = .idle
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // switch state
            if state == .working {
                state = .breakTime
                timeRemaining = breakDuration
                totalDuration = breakDuration
                AudioEngine.shared.stop() // maybe stop during break
            } else if state == .breakTime {
                state = .completed
                timer?.invalidate()
                timer = nil
                // Log session to Supabase here
            }
        }
    }
}
