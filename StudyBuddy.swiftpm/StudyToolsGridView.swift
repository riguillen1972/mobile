import SwiftUI

struct StudyToolsGridView: View {
    @EnvironmentObject var authState: AuthState
    @ObservedObject var subManager = SubscriptionManager.shared
    @State private var selectedTool: StudyTool?
    @State private var showingUpgradeAlert = false
    @State private var upgradeRequiredTier: Tier = .pro
    @State private var showingSubscriptionView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.mainBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(ToolCategory.allCases) { category in
                            VStack(alignment: .leading, spacing: 16) {
                                Text(category.rawValue)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(StudyTool.allCases.filter { $0.category == category }) { tool in
                                        ToolCard(tool: tool, currentTier: subManager.currentTier) {
                                            if subManager.currentTier < tool.requiredTier {
                                                upgradeRequiredTier = tool.requiredTier
                                                showingUpgradeAlert = true
                                            } else {
                                                selectedTool = tool
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Study Tools")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedTool) { tool in
                ToolContainerView(tool: tool)
            }
            .alert("Upgrade Required", isPresented: $showingUpgradeAlert) {
                Button("Cancel", role: .cancel) { }
                Button("View Plans") { showingSubscriptionView = true }
            } message: {
                Text("This tool requires the \(upgradeRequiredTier.rawValue.uppercased()) tier. Please upgrade your subscription to access it.")
            }
            .sheet(isPresented: $showingSubscriptionView) {
                SubscriptionView()
            }
        }
    }
}

struct ToolCard: View {
    let tool: StudyTool
    let currentTier: Tier
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(tool.category.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: tool.iconName)
                            .foregroundColor(tool.category.color)
                            .font(.system(size: 20))
                    }
                    
                    Spacer()
                    
                    if currentTier < tool.requiredTier {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                
                Text(tool.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .background(Color.theme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(currentTier < tool.requiredTier)
        .opacity(currentTier < tool.requiredTier ? 0.6 : 1.0)
    }
}
