import SwiftUI

enum NavigationItem: String, CaseIterable {
    case teacherDashboard = "My Class"
    case focusMode = "Focus Mode"
    case assignments = "My Assignments"
    case aiTutor = "AI Tutor"
    case studyTools = "Study Tools"
    case appGenerator = "App Generator"
    case webTutor = "Web Tutor"
    case homeworkHelp = "Homework Help"
    case scanHomework = "Scan Homework"
    case summarizer = "Summarizer"
    case quizGenerator = "Quiz Generator"
    case flashcards = "Flashcards"
    case bibleVerse = "Bible Verse"
    case progress = "Progress"
    case profile = "Profile"
    
    var iconName: String {
        switch self {
        case .teacherDashboard: return "square.grid.2x2.fill"
        case .focusMode: return "headphones"
        case .assignments: return "tray.full.fill"
        case .aiTutor: return "sparkles"
        case .studyTools: return "books.vertical"
        case .appGenerator: return "globe"
        case .webTutor: return "network"
        case .homeworkHelp: return "questionmark.circle"
        case .scanHomework: return "viewfinder"
        case .summarizer: return "doc.text"
        case .quizGenerator: return "list.bullet.clipboard"
        case .flashcards: return "rectangle.stack"
        case .bibleVerse: return "book"
        case .progress: return "chart.bar.xaxis"
        case .profile: return "person.crop.circle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .teacherDashboard: return Color.theme.accentBlue
        case .focusMode: return Color.theme.accentPurple
        case .assignments: return Color.theme.accentPink
        case .aiTutor: return Color.theme.accentPink
        case .studyTools: return Color.theme.accentOrange
        case .appGenerator: return Color.theme.accentCyan
        case .webTutor: return Color.theme.accentGreen
        case .homeworkHelp: return Color.theme.accentYellow
        case .scanHomework: return Color.theme.accentPurple
        case .summarizer: return Color.theme.accentRed
        case .quizGenerator: return Color.theme.accentCyan
        case .flashcards: return Color.theme.accentPurple
        case .bibleVerse: return Color.theme.accentBlue
        case .progress: return Color.theme.accentGreen
        case .profile: return Color.theme.accentCyan
        }
    }
    
    var hasMaxBadge: Bool {
        return self == .appGenerator || self == .webTutor
    }
    
    var isVisibleToTeachers: Bool {
        switch self {
        case .teacherDashboard, .profile: return true
        default: return false
        }
    }
    
    var isVisibleToStudents: Bool {
        switch self {
        case .teacherDashboard: return false
        default: return true
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var authState: AuthState
    @ObservedObject var subManager = SubscriptionManager.shared
    @Binding var selectedItem: NavigationItem
    var onSignOut: () -> Void
    
    @State private var showingUpgradeAlert = false
    @State private var showingSubscriptionView = false
    
    var body: some View {
        ZStack {
            Color.theme.sidebarBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Header / App Logo
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.theme.primaryGradient)
                            .frame(width: 36, height: 36)
                        Image(systemName: "sparkles")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    
                    Text("Study Buddy AI")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.textPrimary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.theme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                
                // Menu Items
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        let isTeacher = authState.userRole == "teacher"
                        let visibleItems = NavigationItem.allCases.filter { item in
                            // Filter out bottom items like profile from the main scroll
                            if item == .profile { return false }
                            return isTeacher ? item.isVisibleToTeachers : item.isVisibleToStudents
                        }
                        
                        ForEach(visibleItems, id: \.self) { item in
                            SidebarButton(
                                item: item,
                                isSelected: selectedItem == item,
                                action: {
                                    if item.hasMaxBadge && subManager.currentTier != .max {
                                        showingUpgradeAlert = true
                                    } else {
                                        selectedItem = item
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Footer Menu Items
                VStack(spacing: 8) {
                    FooterButton(icon: "person.fill", title: "Profile", iconColor: Color.theme.accentCyan, action: { selectedItem = .profile })
                    FooterButton(icon: "moon.fill", title: "Toggle Theme", iconColor: Color.theme.accentPurple, action: {})
                    FooterButton(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", iconColor: Color.theme.accentRed, action: onSignOut)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .padding(.top, 16)
            }
        }
        .alert("Upgrade to Max Tier Required", isPresented: $showingUpgradeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("View Plans") { showingSubscriptionView = true }
        } message: {
            Text("This feature is exclusive to the MAX tier. Please upgrade your subscription to access it.")
        }
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
        }
    }
}

struct SidebarButton: View {
    let item: NavigationItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(item.iconColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: item.iconName)
                        .foregroundColor(item.iconColor)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(item.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? Color.theme.textPrimary : Color.theme.textSecondary)
                
                Spacer()
                
                if item.hasMaxBadge {
                    Text("MAX")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.accentYellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.theme.accentYellow.opacity(0.2))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.theme.accentYellow.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.theme.activeGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.theme.activeBorderGradient, lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FooterButton: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.theme.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.theme.cardBackground.opacity(0.5))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
