import SwiftUI

struct AIChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.role == .user {
                Spacer(minLength: 40)
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.theme.primaryGradient)
                    .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
            } else {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(Color.theme.cardBackground)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    Image(systemName: "sparkles")
                        .foregroundColor(Color.theme.accentPink)
                        .font(.system(size: 14, weight: .bold))
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(Color.theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                
                Spacer(minLength: 40)
            }
        }
        .padding(.vertical, 4)
    }
}

// Extension for custom corner radii
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
