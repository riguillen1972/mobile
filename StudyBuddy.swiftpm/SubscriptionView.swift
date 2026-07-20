import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subManager = SubscriptionManager.shared
    @StateObject private var storeKit = StoreKitManager.shared
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.mainBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Choose Your Plan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 16)
                        
                        Text("Unlock the full potential of Study Buddy AI.")
                            .foregroundColor(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 16)
                        
                        // FREE TIER
                        PlanCard(
                            tier: .free,
                            title: "Free",
                            price: "$0 / month",
                            features: [
                                "250k tokens of Gemini 2.5 Flash-Lite",
                                "Basic Study Smart Tools",
                                "No Focus Mode"
                            ],
                            currentTier: subManager.currentTier,
                            isProcessing: isProcessing,
                            action: {
                                Task { await upgrade(to: .free) }
                            }
                        )
                        
                        // PRO TIER
                        PlanCard(
                            tier: .pro,
                            title: "Pro",
                            price: getPrice(for: .pro, defaultPrice: "$15.00 / month"),
                            features: [
                                "1M tokens of Gemini 2.5 Flash",
                                "500k tokens of Gemini 2.5 Pro",
                                "Make It Click AI Tools",
                                "Focus Mode (up to 25m)"
                            ],
                            currentTier: subManager.currentTier,
                            isProcessing: isProcessing,
                            action: {
                                Task { await upgrade(to: .pro) }
                            }
                        )
                        
                        // MAX TIER
                        PlanCard(
                            tier: .max,
                            title: "Max",
                            price: getPrice(for: .max, defaultPrice: "$30.00 / month"),
                            features: [
                                "2M tokens of Claude 4.5 Haiku",
                                "2M tokens of Gemini 2.5 Flash",
                                "All AI Study Tools",
                                "App Generator & Web Tutor",
                                "Unlimited Focus Mode"
                            ],
                            currentTier: subManager.currentTier,
                            isProcessing: isProcessing,
                            action: {
                                Task { await upgrade(to: .max) }
                            }
                        )
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarItems(trailing: Button("Close") { dismiss() })
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Upgrade Failed"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
            .task {
                await storeKit.fetchProducts()
            }
        }
    }
    
    private func getPrice(for tier: Tier, defaultPrice: String) -> String {
        if let productId = storeKit.productDict[tier],
           let product = storeKit.storeProducts.first(where: { $0.id == productId }) {
            return "\(product.displayPrice) / month"
        }
        return defaultPrice
    }
    
    private func upgrade(to tier: Tier) async {
        isProcessing = true
        do {
            try await subManager.upgrade(to: tier)
            dismiss()
        } catch {
            print("Upgrade failed: \(error)")
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        isProcessing = false
    }
}

struct PlanCard: View {
    let tier: Tier
    let title: String
    let price: String
    let features: [String]
    let currentTier: Tier
    let isProcessing: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.accentCyan)
                Spacer()
                if currentTier == tier {
                    Text("Current Plan")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.theme.accentGreen.opacity(0.2))
                        .foregroundColor(Color.theme.accentGreen)
                        .cornerRadius(8)
                }
            }
            
            Text(price)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.theme.accentGreen)
                        Text(feature)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                }
            }
            .padding(.vertical, 8)
            
            Button(action: action) {
                HStack {
                    Spacer()
                    if isProcessing {
                        ProgressView()
                    } else {
                        Text(currentTier == tier ? "Selected" : "Select \(title)")
                    }
                    Spacer()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(currentTier == tier ? AnyShapeStyle(Color.gray) : AnyShapeStyle(Color.theme.primaryGradient))
                .cornerRadius(12)
            }
            .disabled(currentTier == tier || isProcessing)
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentTier == tier ? Color.theme.accentCyan : Color.clear, lineWidth: 2)
        )
    }
}
