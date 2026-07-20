import SwiftUI

struct StudyStreaksView: View {
    @State private var streakData: APIClient.StreakData?
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    // Level calculation (1 level = 1000 XP)
    var currentLevel: Int {
        guard let xp = streakData?.total_xp else { return 1 }
        return (xp / 1000) + 1
    }
    
    var xpToNextLevel: Int {
        guard let xp = streakData?.total_xp else { return 1000 }
        return 1000 - (xp % 1000)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                if isLoading {
                    ProgressView("Loading Streaks...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.top, 64)
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(Color.theme.accentRed)
                        .padding()
                    Button("Retry") {
                        Task { await loadData() }
                    }
                } else {
                    // Flame & Streak
                    VStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                            .shadow(color: .orange.opacity(0.5), radius: 20, x: 0, y: 10)
                        
                        Text("\(streakData?.current_streak ?? 0)")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Day Streak")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(Color.theme.textSecondary)
                        
                        Text("Longest Streak: \(streakData?.longest_streak ?? 0) days")
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                            .padding(.top, 4)
                    }
                    .padding(.top, 32)
                    
                    // XP & Levels Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Level \(currentLevel)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Scholar")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.accentBlue)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(streakData?.total_xp ?? 0) XP")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.theme.accentPurple)
                                Text("\(xpToNextLevel) XP to next level")
                                    .font(.caption)
                                    .foregroundColor(Color.gray)
                            }
                        }
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .frame(height: 16)
                                    .foregroundColor(Color.black.opacity(0.3))
                                
                                let progress = CGFloat((streakData?.total_xp ?? 0) % 1000) / 1000.0
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .frame(width: geometry.size.width * max(progress, 0.05), height: 16)
                                    .foregroundColor(Color.theme.accentPurple)
                            }
                        }
                        .frame(height: 16)
                    }
                    .padding(24)
                    .background(Color.theme.cardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Daily Goals Placeholder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Goals")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        GoalRow(icon: "brain.head.profile", title: "Complete 1 Quiz", xp: 50, isCompleted: false)
                        GoalRow(icon: "sparkles", title: "Use an AI Tool", xp: 20, isCompleted: true)
                        GoalRow(icon: "book.fill", title: "Study for 30 mins", xp: 100, isCompleted: false)
                    }
                    .padding(24)
                    .background(Color.theme.cardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.theme.mainBackground.ignoresSafeArea())
        .onAppear {
            Task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        errorMessage = ""
        do {
            let data = try await APIClient.shared.getGamificationData()
            withAnimation {
                streakData = data
            }
        } catch {
            errorMessage = "Failed to load gamification data. Make sure Supabase schema is applied and you are logged in."
        }
        isLoading = false
    }
}

struct GoalRow: View {
    let icon: String
    let title: String
    let xp: Int
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isCompleted ? Color.theme.accentGreen : Color.theme.accentBlue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(isCompleted ? Color.gray : .white)
                    .strikethrough(isCompleted)
                Text("+\(xp) XP")
                    .font(.caption)
                    .foregroundColor(Color.theme.accentPurple)
            }
            
            Spacer()
            
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isCompleted ? Color.theme.accentGreen : Color.gray)
        }
    }
}
