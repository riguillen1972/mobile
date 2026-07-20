import SwiftUI

struct RolePickerView: View {
    @EnvironmentObject var authState: AuthState
    
    @State private var selectedRole: String? = nil
    @State private var gradeLevel: String = ""
    @State private var careerField: String = ""
    @State private var studentClassCode: String = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.theme.accentBlue)
                        Text("Study Buddy AI")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("Choose Your Role")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 16)
                    
                    Text("Select how you'll be using Study Buddy AI")
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                ScrollView {
                    VStack(spacing: 16) {
                        RoleCard(
                            roleId: "teacher",
                            iconName: "person.fill",
                            title: "Teacher",
                            subtitle: "Manage & Monitor",
                            description: "Set class codes, monitor student progress, and customize AI limits",
                            isSelected: selectedRole == "teacher",
                            action: { selectedRole = "teacher" }
                        )
                        
                        RoleCard(
                            roleId: "college",
                            iconName: "graduationcap.fill",
                            title: "College Student",
                            subtitle: "Career-Focused",
                            description: "AI optimized for your career path and field of study",
                            isSelected: selectedRole == "college",
                            action: { selectedRole = "college" }
                        )
                        
                        if selectedRole == "college" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Career Field / Major")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                TextField("e.g. Computer Science", text: $careerField)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                
                                Text("Class Code (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.top, 8)
                                TextField("e.g. A7X9WQ", text: $studentClassCode)
                                    .textInputAutocapitalization(.characters)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                        }
                        
                        RoleCard(
                            roleId: "k12",
                            iconName: "person.2.fill",
                            title: "Elementary to High School",
                            subtitle: "Study Buddy AI",
                            description: "Your personal AI-powered study companion",
                            isSelected: selectedRole == "k12",
                            action: { selectedRole = "k12" }
                        )
                        
                        if selectedRole == "k12" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Grade Level")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Picker("Grade", selection: $gradeLevel) {
                                    Text("Select Grade").tag("")
                                    ForEach(1...12, id: \.self) { grade in
                                        Text("Grade \(grade)").tag(String(grade))
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .tint(.white)
                                
                                Text("Class Code (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.top, 8)
                                TextField("e.g. A7X9WQ", text: $studentClassCode)
                                    .textInputAutocapitalization(.characters)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                Button(action: {
                    guard let role = selectedRole else { return }
                    isLoading = true
                    Task {
                        await authState.updateUserRole(
                            role: role,
                            gradeLevel: role == "k12" ? gradeLevel : nil,
                            careerField: role == "college" ? careerField : nil,
                            classCode: studentClassCode
                        )
                        isLoading = false
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedRole == nil ? Color.gray : Color.theme.accentBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedRole == nil || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

struct RoleCard: View {
    let roleId: String
    let iconName: String
    let title: String
    let subtitle: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 80, height: 80)
                    Image(systemName: iconName)
                        .font(.system(size: 32))
                        .foregroundColor(isSelected ? Color.theme.accentBlue : .gray)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? Color.theme.accentBlue : .gray)
                }
                
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.theme.accentBlue : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
