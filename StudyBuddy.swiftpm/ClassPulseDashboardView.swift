import SwiftUI

struct ClassPulseDashboardView: View {
    let classId: String
    
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(Color.theme.accentBlue)
            
            Text("Class Pulse")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Analytics on student engagement and AI study tool usage will appear here.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.mainBackground)
    }
}
