import Foundation
import ClassKit

@MainActor
class ClassKitManager: NSObject, ObservableObject {
    static let shared = ClassKitManager()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date? = nil
    
    private override init() {
        super.init()
        // Enable ClassKit development mode for testing
        CLSDataStore.shared.delegate = self
    }
    
    // MARK: - Context Registration
    
    /// Register a class as a top-level CLSContext
    func registerClass(_ classModel: ClassModel) {
        let identifierPath = ["class-\(classModel.id)"]
        
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: identifierPath) { (context, error) in
            if let existingContext = context {
                // Update existing context
                existingContext.title = classModel.name
                existingContext.topic = .init(rawValue: classModel.subject ?? "General")
                CLSDataStore.shared.save { error in
                    if let error = error {
                        print("[ClassKit] Error updating class context: \(error)")
                    }
                }
            } else {
                // Create new context
                let classContext = CLSContext(
                    type: .course,
                    identifier: "class-\(classModel.id)",
                    title: classModel.name
                )
                classContext.topic = .init(rawValue: classModel.subject ?? "General")
                classContext.isAssignable = false
                classContext.displayOrder = 0
                
                CLSDataStore.shared.mainAppContext.addChildContext(classContext)
                CLSDataStore.shared.save { error in
                    if let error = error {
                        print("[ClassKit] Error saving class context: \(error)")
                    } else {
                        print("[ClassKit] Registered class: \(classModel.name)")
                    }
                }
            }
        }
    }
    
    /// Register a context pack as an assignable activity under its class
    func registerContextPack(_ pack: ContextPackModel) {
        let classId = pack.class_id
        
        let classPath = ["class-\(classId)"]
        let packIdentifier = "pack-\(pack.id)"
        
        // First ensure the class context exists
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: classPath) { (classContext, error) in
            guard let classContext = classContext else {
                print("[ClassKit] Class context not found for pack registration.")
                return
            }
            
            let packPath = classPath + [packIdentifier]
            
            CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: packPath) { (existing, error) in
                if let existingContext = existing {
                    existingContext.title = pack.title
                    existingContext.summary = "Type: \(pack.type) | Subject: \(pack.subject ?? "General")"
                    CLSDataStore.shared.save { error in
                        if let error = error {
                            print("[ClassKit] Error updating pack context: \(error)")
                        }
                    }
                } else {
                    let packContext = CLSContext(
                        type: .task,
                        identifier: packIdentifier,
                        title: pack.title
                    )
                    packContext.summary = "Type: \(pack.type) | Subject: \(pack.subject ?? "General")"
                    packContext.isAssignable = true
                    packContext.displayOrder = 1
                    
                    // Add suggested age range for educational content
                    if let topic = pack.subject {
                        packContext.topic = .init(rawValue: topic)
                    }
                    
                    classContext.addChildContext(packContext)
                    CLSDataStore.shared.save { error in
                        if let error = error {
                            print("[ClassKit] Error saving pack context: \(error)")
                        } else {
                            print("[ClassKit] Registered context pack: \(pack.title)")
                        }
                    }
                }
            }
        }
    }
    
    /// Sync all classes and context packs to ClassKit
    func syncAll(classes: [ClassModel], contextPacks: [ContextPackModel]) async {
        isSyncing = true
        
        // Register all classes first
        for cls in classes {
            registerClass(cls)
        }
        
        // Small delay to ensure class contexts are saved
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Register all context packs under their classes
        for pack in contextPacks {
            registerContextPack(pack)
        }
        
        // Small delay for saves to complete
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        isSyncing = false
        lastSyncDate = Date()
        print("[ClassKit] Full sync complete. \(classes.count) classes, \(contextPacks.count) packs.")
    }
    
    // MARK: - Activity Tracking (Student Side)
    
    /// Start tracking an activity when a student opens an assignment
    func startActivity(classId: String, packId: String) {
        let identifierPath = ["class-\(classId)", "pack-\(packId)"]
        
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: identifierPath) { (context, error) in
            guard let context = context else {
                print("[ClassKit] Context not found for activity start.")
                return
            }
            
            context.becomeActive()
            context.createNewActivity()
            context.currentActivity?.start()
            
            CLSDataStore.shared.save { error in
                if let error = error {
                    print("[ClassKit] Error starting activity: \(error)")
                } else {
                    print("[ClassKit] Activity started for pack: \(packId)")
                }
            }
        }
    }
    
    /// Stop and report progress when a student completes an assignment
    func completeActivity(classId: String, packId: String, score: Double? = nil, progress: Double = 1.0) {
        let identifierPath = ["class-\(classId)", "pack-\(packId)"]
        
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: identifierPath) { (context, error) in
            guard let context = context,
                  let activity = context.currentActivity else {
                print("[ClassKit] No active activity to complete.")
                return
            }
            
            // Add progress item
            if progress > 0 {
                let progressItem = CLSQuantityItem(identifier: "completion", title: "Completion")
                progressItem.quantity = progress
                activity.addAdditionalActivityItem(progressItem)
            }
            
            // Add score if available
            if let score = score {
                let scoreItem = CLSScoreItem(identifier: "score", title: "Score", score: score, maxScore: 1.0)
                activity.addAdditionalActivityItem(scoreItem)
            }
            
            activity.stop()
            context.resignActive()
            
            CLSDataStore.shared.save { error in
                if let error = error {
                    print("[ClassKit] Error completing activity: \(error)")
                } else {
                    print("[ClassKit] Activity completed for pack: \(packId) with progress: \(progress)")
                }
            }
        }
    }
}

// MARK: - CLSDataStoreDelegate

extension ClassKitManager: CLSDataStoreDelegate {
    nonisolated func createContext(forIdentifier identifier: String, parentContext: CLSContext, parentIdentifierPath: [String]) -> CLSContext? {
        // Called when Schoolwork needs a context that doesn't exist yet
        // Return a placeholder context that will be populated when the app loads data
        let context = CLSContext(type: .task, identifier: identifier, title: identifier)
        context.isAssignable = true
        return context
    }
}
