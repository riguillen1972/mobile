import SwiftUI
import Charts

struct ProgressViewScreen: View {
    let displayName: String
    
    @State private var logs: [ProgressLog] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Your Progress")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.theme.textPrimary)
                    .padding(.horizontal, 40)
                    .padding(.top, 24)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if logs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 64))
                            .foregroundColor(Color.theme.textSecondary)
                        Text("No progress data yet.")
                            .font(.headline)
                            .foregroundColor(Color.theme.textSecondary)
                        Text("Complete quizzes or use the tutor to start tracking!")
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Stats Overview
                            HStack(spacing: 24) {
                                StatCard(title: "Activities", value: "\(logs.count)", icon: "list.clipboard")
                                StatCard(title: "Minutes", value: "\(logs.reduce(0) { $0 + $1.durationMinutes })", icon: "clock")
                                let scores = logs.compactMap { $0.score }
                                let avgScore = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
                                StatCard(title: "Avg Score", value: "\(avgScore)%", icon: "star.fill")
                            }
                            
                            // Activity Chart
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Activity Breakdown")
                                    .font(.headline)
                                    .foregroundColor(Color.theme.textPrimary)
                                
                                Chart {
                                    ForEach(groupedByActivityType(), id: \.type) { item in
                                        BarMark(
                                            x: .value("Activity", item.type),
                                            y: .value("Count", item.count)
                                        )
                                        .foregroundStyle(Color.theme.accentCyan.gradient)
                                    }
                                }
                                .frame(height: 250)
                                .chartYAxis {
                                    AxisMarks(position: .leading) { value in
                                        AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                                        AxisValueLabel()
                                            .foregroundStyle(Color.theme.textSecondary)
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisValueLabel()
                                            .foregroundStyle(Color.theme.textSecondary)
                                    }
                                }
                            }
                            .padding(24)
                            .background(Color.theme.cardBackground)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await fetchLogs()
            }
        }
    }
    
    private func fetchLogs() async {
        do {
            let fetchedLogs = try await ProgressService.shared.fetchLogs()
            await MainActor.run {
                self.logs = fetchedLogs
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch logs: \\(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
    
    private func groupedByActivityType() -> [(type: String, count: Int)] {
        var dict: [String: Int] = [:]
        for log in logs {
            dict[log.activityType, default: 0] += 1
        }
        return dict.map { (type: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color.theme.accentCyan)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
            }
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color.theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
    }
}
