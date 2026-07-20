import SwiftUI
import ClassKit

struct TeacherDashboardView: View {
    let displayName: String
    @EnvironmentObject var authState: AuthState
    
    @State private var selectedTab = 0
    @State private var classes: [ClassModel] = []
    @State private var contextPacks: [ContextPackModel] = []
    @State private var isLoading = false
    @State private var showSyncSuccess = false
    @ObservedObject private var classKitManager = ClassKitManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Teacher Console")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Manage your classes and AI context packs.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Sync to Schoolwork button
                Button(action: {
                    Task {
                        await classKitManager.syncAll(classes: classes, contextPacks: contextPacks)
                        showSyncSuccess = true
                    }
                }) {
                    HStack(spacing: 8) {
                        if classKitManager.isSyncing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(classKitManager.isSyncing ? "Syncing..." : "Sync to Schoolwork")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.theme.accentPurple)
                    .cornerRadius(20)
                }
                .disabled(classKitManager.isSyncing || classes.isEmpty)
                .padding(.top, 4)
                
                if let lastSync = classKitManager.lastSyncDate {
                    Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Tabs
            Picker("Teacher Tabs", selection: $selectedTab) {
                Text("Classes").tag(0)
                Text("Context Packs").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 24)
            
            // Tab Content
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                if selectedTab == 0 {
                    ClassManagerView(classes: $classes, onRefresh: loadData)
                } else {
                    ContentCreatorView(classes: classes, contextPacks: $contextPacks, onRefresh: loadData)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.mainBackground)
        .onAppear {
            loadData()
        }
        .alert("Synced to Schoolwork!", isPresented: $showSyncSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your \(classes.count) classes and \(contextPacks.count) context packs are now available in Apple Schoolwork.")
        }
    }
    
    private func loadData() {
        isLoading = true
        Task {
            do {
                let fetchedClasses = try await APIClient.shared.getClasses()
                let fetchedPacks = try await APIClient.shared.getContextPacks()
                await MainActor.run {
                    self.classes = fetchedClasses
                    self.contextPacks = fetchedPacks
                    self.isLoading = false
                }
            } catch {
                print("Error loading teacher data: \(error)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}
