import SwiftUI

struct ProfileViewScreen: View {
    let displayName: String
    @ObservedObject var authState = AuthState.shared
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Text(displayName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)
                    .padding(.top, 24)
                
                VStack(spacing: 24) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.theme.accentPurple, Color.theme.accentPink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 120, height: 120)
                        
                        Text(authState.currentUser?.email?.prefix(1).uppercased() ?? "U")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Info
                    VStack(spacing: 8) {
                        Text(authState.currentUser?.email ?? "Unknown User")
                            .font(.title2)
                            .foregroundColor(Color.theme.textPrimary)
                        Text("Pro Member")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.theme.accentGreen.opacity(0.2))
                            .foregroundColor(Color.theme.accentGreen)
                            .cornerRadius(12)
                    }
                    
                    Divider().background(Color.white.opacity(0.1)).padding(.vertical, 16)
                    
                    Button(action: {
                        Task {
                            await authState.signOut()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .foregroundColor(Color.theme.accentRed)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.theme.accentRed.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(32)
                .background(Color.theme.cardBackground)
                .cornerRadius(24)
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}
