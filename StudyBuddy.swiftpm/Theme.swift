import SwiftUI

extension Color {
    static let theme = Theme()
}

struct Theme {
    // Backgrounds
    let mainBackground = Color(red: 10/255, green: 14/255, blue: 26/255) // Deep space blue #0A0E1A
    let sidebarBackground = Color(red: 17/255, green: 24/255, blue: 39/255) // Slightly lighter dark blue #111827
    let cardBackground = Color(red: 30/255, green: 41/255, blue: 59/255).opacity(0.8) // Glassy dark #1E293B
    
    // Gradients
    let primaryGradient = LinearGradient(colors: [Color(red: 56/255, green: 189/255, blue: 248/255), Color(red: 59/255, green: 130/255, blue: 246/255)], startPoint: .topLeading, endPoint: .bottomTrailing) // Blue to cyan
    let activeGradient = LinearGradient(colors: [Color(red: 139/255, green: 92/255, blue: 246/255).opacity(0.3), Color(red: 236/255, green: 72/255, blue: 153/255).opacity(0.3)], startPoint: .leading, endPoint: .trailing) // Purple to pink overlay
    let activeBorderGradient = LinearGradient(colors: [Color(red: 139/255, green: 92/255, blue: 246/255), Color(red: 236/255, green: 72/255, blue: 153/255)], startPoint: .leading, endPoint: .trailing) // Solid purple to pink
    
    // Text
    let textPrimary = Color.white
    let textSecondary = Color(red: 156/255, green: 163/255, blue: 175/255) // Gray #9CA3AF
    
    // Accents
    let accentPink = Color(red: 236/255, green: 72/255, blue: 153/255)
    let accentOrange = Color(red: 249/255, green: 115/255, blue: 22/255)
    let accentCyan = Color(red: 6/255, green: 182/255, blue: 212/255)
    let accentGreen = Color(red: 16/255, green: 185/255, blue: 129/255)
    let accentYellow = Color(red: 234/255, green: 179/255, blue: 8/255)
    let accentPurple = Color(red: 168/255, green: 85/255, blue: 247/255)
    let accentRed = Color(red: 239/255, green: 68/255, blue: 68/255)
    let accentBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
}
