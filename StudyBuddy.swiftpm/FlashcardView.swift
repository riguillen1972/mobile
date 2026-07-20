import SwiftUI

struct FlashcardView: View {
    let card: Flashcard
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // Front
            CardFace(text: card.question, isFront: true)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            // Back
            CardFace(text: card.answer, isFront: false)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                isFlipped.toggle()
            }
        }
    }
}

struct CardFace: View {
    let text: String
    let isFront: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Text(text)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color.theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
            
            Text(isFront ? "Tap to flip" : "Answer")
                .font(.caption)
                .foregroundColor(Color.theme.textSecondary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isFront ? Color.theme.cardBackground : Color(red: 25/255, green: 35/255, blue: 60/255).opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}
