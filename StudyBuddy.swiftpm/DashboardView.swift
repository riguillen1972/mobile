import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authState: AuthState
    @State private var selectedItem: NavigationItem = .aiTutor
    @State private var isSidebarVisible = false
    @State private var showingJoinClass = false
    /// Only true when we have positively confirmed the student has zero enrollments
    @State private var confirmedNotEnrolled = false
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        Group {
            if sizeClass == .compact {
                ZStack(alignment: .leading) {
                    detailContent
                    
                    if isSidebarVisible {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { isSidebarVisible = false }
                            }
                            .zIndex(1)
                        
                        SidebarView(
                            selectedItem: $selectedItem,
                            onSignOut: {
                                Task { await authState.signOut() }
                            }
                        )
                        .frame(width: 280)
                        .transition(.move(edge: .leading))
                        .zIndex(2)
                    }
                }
                .onChange(of: selectedItem) {
                    withAnimation { isSidebarVisible = false }
                }
            } else {
                NavigationSplitView {
                    SidebarView(
                        selectedItem: $selectedItem,
                        onSignOut: {
                            Task { await authState.signOut() }
                        }
                    )
                    .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 300)
                    .navigationBarHidden(true)
                } detail: {
                    detailContent
                }
            }
        }
        .onAppear {
            if authState.userRole == "teacher" {
                selectedItem = .teacherDashboard
            }
        }
        .onChange(of: authState.userRole) { _, newRole in
            if newRole == "teacher" {
                selectedItem = .teacherDashboard
            }
        }
        .onChange(of: authState.session) { _, newSession in
            if newSession != nil {
                Task { await runEnrollmentCheck() }
            }
        }
        .task {
            // Wait briefly for auth to initialize, then check enrollment
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await runEnrollmentCheck()
        }
    }
    
    private func runEnrollmentCheck() async {
        guard authState.userRole != "teacher" else { return }
        guard authState.session != nil else { return }
        do {
            let classes = try await APIClient.shared.getClasses()
            await MainActor.run {
                withAnimation {
                    // Only show the button if we positively confirmed zero classes
                    self.confirmedNotEnrolled = classes.isEmpty
                }
            }
        } catch {
            // On failure, default to hiding the button (assume enrolled)
            await MainActor.run {
                self.confirmedNotEnrolled = false
            }
        }
    }
    
    /// Only show Join Class if we positively confirmed the student has no classes
    private var showJoinClassButton: Bool {
        authState.userRole != "teacher" && confirmedNotEnrolled
    }
    
    @ViewBuilder
    var detailContent: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            if sizeClass == .compact {
                VStack {
                    HStack {
                        Button(action: { withAnimation { isSidebarVisible.toggle() } }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        Spacer()
                        
                        if showJoinClassButton {
                            Button(action: { showingJoinClass = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Join Class")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.theme.accentBlue)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    Spacer()
                }
                .zIndex(100)
            }
            
            if let user = authState.currentUser {
                let displayName = user.userMetadata["display_name"]?.value as? String ?? user.email?.components(separatedBy: "@").first ?? "Student"
                
                Group {
                    switch selectedItem {
                case .teacherDashboard:
                    TeacherDashboardView(displayName: displayName)
                case .focusMode:
                    FocusModeView()
                case .assignments:
                    StudentAssignmentsView(displayName: displayName)
                case .studyTools:
                    StudyToolsGridView()
                case .aiTutor:
                    AITutorView(displayName: displayName)
                case .summarizer:
                    SummarizerView(displayName: displayName)
                case .homeworkHelp:
                    HomeworkHelpView(displayName: displayName)
                case .scanHomework:
                    ScanHomeworkView(displayName: displayName)
                case .flashcards:
                    FlashcardsView(displayName: displayName)
                case .quizGenerator:
                    QuizGeneratorView(displayName: displayName)
                case .bibleVerse:
                    BibleVerseView(displayName: displayName)
                case .appGenerator:
                    AppGeneratorView(displayName: displayName)

                    case .webTutor:
                        WebTutorView(displayName: displayName)
                    case .profile:
                        ProfileViewScreen(displayName: displayName)
                    case .progress:
                        ProgressViewScreen(displayName: displayName)
                    default:
                        VStack(spacing: 16) {
                            Image(systemName: selectedItem.iconName)
                                .font(.system(size: 64))
                                .foregroundColor(selectedItem.iconColor)
                            Text("\(selectedItem.rawValue) is coming soon.")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .sheet(isPresented: $showingJoinClass) {
                    JoinClassView {
                        confirmedNotEnrolled = false
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .navigationBarHidden(true)
    }
}
