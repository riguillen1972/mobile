import SwiftUI

struct JoinClassView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var joinCode = ""
    @State private var isEnrolling = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var onEnrollSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.mainBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color.theme.accentBlue)
                        .padding(.top, 40)
                    
                    Text("Join a Class")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Enter the 6-character join code provided by your teacher.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    TextField("Enter Join Code", text: $joinCode)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(Color.theme.accentRed)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .foregroundColor(Color.theme.accentGreen)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    if isEnrolling {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.bottom, 40)
                    } else {
                        Button(action: enroll) {
                            Text("Join Class")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(joinCode.count >= 5 ? Color.theme.accentBlue : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(joinCode.count < 5)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func enroll() {
        isEnrolling = true
        errorMessage = ""
        Task {
            do {
                let msg = try await APIClient.shared.enrollInClass(joinCode: joinCode)
                await MainActor.run {
                    successMessage = msg
                    isEnrolling = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onEnrollSuccess()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isEnrolling = false
                }
            }
        }
    }
}
