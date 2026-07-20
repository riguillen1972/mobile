import SwiftUI
import Supabase

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color(red: 10/255.0, green: 14/255.0, blue: 26/255.0).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Study Buddy AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(isSignUp ? "Create an account to start learning" : "Sign in to continue your learning journey")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Full Name", text: $name)
                            .padding()
                            .background(Color(red: 30/255.0, green: 41/255.0, blue: 59/255.0))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(red: 30/255.0, green: 41/255.0, blue: 59/255.0))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(red: 30/255.0, green: 41/255.0, blue: 59/255.0))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding(.top, 16)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Button(action: {
                    Task {
                        await authenticate()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 99/255.0, green: 102/255.0, blue: 241/255.0))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty))
                
                Button(action: {
                    isSignUp.toggle()
                    errorMessage = ""
                }) {
                    Text(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                        .foregroundColor(Color(red: 99/255.0, green: 102/255.0, blue: 241/255.0))
                        .font(.footnote)
                }
                
                Spacer()
            }
            .padding(32)
        }
    }
    
    private func authenticate() async {
        isLoading = true
        errorMessage = ""
        
        do {
            if isSignUp {
                try await SupabaseManager.shared.client.auth.signUp(
                    email: email,
                    password: password,
                    data: ["full_name": .string(name)]
                )
                // Auto sign-in after signup (works when email confirmation is disabled in Supabase)
                try await SupabaseManager.shared.client.auth.signIn(
                    email: email,
                    password: password
                )
            } else {
                try await SupabaseManager.shared.client.auth.signIn(
                    email: email,
                    password: password
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
