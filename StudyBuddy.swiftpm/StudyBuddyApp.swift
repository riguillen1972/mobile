import SwiftUI
import ClassKit

@main
struct StudyBuddyApp: App {
    @StateObject private var authState = AuthState.shared
    
    init() {
        // Initialize ClassKit delegate on app launch
        _ = ClassKitManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authState.isLoading {
                    ZStack {
                        Color(red: 10/255.0, green: 14/255.0, blue: 26/255.0).ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                } else if authState.session != nil {
                    if authState.needsRolePicker {
                        RolePickerView()
                            .environmentObject(authState)
                    } else {
                        DashboardView()
                            .environmentObject(authState)
                    }
                } else {
                    AuthView()
                }
            }
            .preferredColorScheme(.dark)
            .task(id: authState.session?.user.id) {
                if authState.session != nil {
                    await SubscriptionManager.shared.refreshState()
                }
            }
        }
    }
}
