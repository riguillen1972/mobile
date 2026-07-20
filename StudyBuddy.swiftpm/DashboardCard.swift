import SwiftUI

struct DashboardCard: View {
    let iconName: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                // Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor)
                        .frame(width: 48, height: 48)
                    Image(systemName: iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Spacer(minLength: 16)
                
                // Texts
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textSecondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            // Add a subtle drop shadow
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
