import SwiftUI

struct StudentAssignmentsView: View {
    let displayName: String
    @EnvironmentObject var authState: AuthState
    
    @State private var classes: [ClassModel] = []
    @State private var assignments: [ContextPackModel] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("My Assignments")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Complete work assigned by your teachers.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            if isLoading {
                Spacer()
                ProgressView("Loading assignments...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                Spacer()
            } else if !errorMessage.isEmpty {
                Spacer()
                Text(errorMessage)
                    .foregroundColor(Color.theme.accentRed)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else if assignments.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.theme.accentGreen)
                    Text("You're all caught up!")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("No active assignments from your teachers.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(assignments) { assignment in
                            let className = classes.first(where: { $0.id == assignment.class_id })?.name ?? "Class"
                            AssignmentCard(assignment: assignment, className: className)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.mainBackground)
        .onAppear {
            loadAssignments()
        }
    }
    
    private func loadAssignments() {
        isLoading = true
        Task {
            do {
                let fetchedClasses = try await APIClient.shared.getClasses()
                await MainActor.run { self.classes = fetchedClasses }
                
                var allAssignments: [ContextPackModel] = []
                for cls in fetchedClasses {
                    let packs = try await APIClient.shared.getContextPacks(classId: cls.id)
                    allAssignments.append(contentsOf: packs)
                }
                
                // Filter only assignments (e.g. homework, quiz)
                let activeAssignments = allAssignments.filter { $0.type == "homework" || $0.type == "quiz" }
                
                await MainActor.run {
                    self.assignments = activeAssignments
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load assignments: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

struct AssignmentCard: View {
    let assignment: ContextPackModel
    let className: String
    
    @State private var showingTool = false
    @EnvironmentObject var authState: AuthState
    
    var body: some View {
        Button(action: {
            showingTool = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(assignment.type.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForType(assignment.type).opacity(0.2))
                        .foregroundColor(colorForType(assignment.type))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                Text(assignment.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.gray)
                    Text(className)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showingTool, onDismiss: {
            // Report activity completion when student closes the assignment
            let classId = assignment.class_id
            ClassKitManager.shared.completeActivity(classId: classId, packId: assignment.id)
        }) {
            // Depending on the type, we launch the appropriate tool.
            if assignment.type == "quiz" {
                ToolContainerView(tool: .examOracle)
            } else {
                ToolContainerView(tool: .feynmanMode)
            }
        }
        .onChange(of: showingTool) { _, isShowing in
            if isShowing {
                // Start ClassKit activity tracking when student opens assignment
                ClassKitManager.shared.startActivity(classId: assignment.class_id, packId: assignment.id)
            }
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "lesson": return Color.theme.accentBlue
        case "homework": return Color.theme.accentPurple
        case "quiz": return Color.theme.accentPink
        case "rubric": return Color.theme.accentOrange
        default: return Color.gray
        }
    }
}
