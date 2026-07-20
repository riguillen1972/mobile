import SwiftUI
import UniformTypeIdentifiers

struct ContentCreatorView: View {
    let classes: [ClassModel]
    @Binding var contextPacks: [ContextPackModel]
    var onRefresh: () -> Void
    
    @State private var showingUploadModal = false
    @State private var selectedClassId = ""
    @State private var packTitle = ""
    @State private var packSubject = ""
    @State private var packType = "lesson"
    @State private var rawContent = ""
    
    @State private var isUploading = false
    @State private var errorMessage = ""
    
    @State private var isFetchingSuggestion = false
    @State private var aiSuggestion: TeacherSuggestion? = nil
    
    @State private var showingFileImporter = false
    
    let packTypes = ["lesson", "homework", "quiz", "rubric"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("Context Packs")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showingUploadModal = true }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("New Pack")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.theme.accentPurple)
                        .cornerRadius(20)
                    }
                    .disabled(classes.isEmpty)
                }
                .padding(.horizontal)
                
                if classes.isEmpty {
                    Text("You need to create a class before you can upload a Context Pack.")
                        .foregroundColor(Color.theme.accentRed)
                        .padding()
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(Color.theme.accentRed)
                        .padding()
                }
                
                if contextPacks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Context Packs")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Upload a syllabus, rubric, or assignment. AI will parse it and constrain student tools based on your content.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(contextPacks) { pack in
                        ContextPackCard(pack: pack, className: classes.first(where: { $0.id == pack.class_id })?.name ?? "Unknown Class")
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingUploadModal) {
            NavigationView {
                Form {
                    Section(header: Text("Context Pack Details")) {
                        Picker("Class", selection: $selectedClassId) {
                            Text("Select a Class").tag("")
                            ForEach(classes) { cls in
                                Text(cls.name).tag(cls.id)
                            }
                        }
                        
                        TextField("Title (e.g. Week 1 Syllabus)", text: $packTitle)
                        TextField("Subject (Optional)", text: $packSubject)
                        
                        Picker("Type", selection: $packType) {
                            ForEach(packTypes, id: \.self) { type in
                                Text(type.capitalized).tag(type)
                            }
                        }
                    }
                    
                    if isFetchingSuggestion {
                        Section {
                            HStack {
                                Spacer()
                                ProgressView("Analyzing class progress...")
                                Spacer()
                            }
                        }
                    } else if let suggestion = aiSuggestion {
                        Section(header: Text("AI Suggestion (Based on Class Progress)")) {
                            Text(suggestion.suggestion)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.vertical, 4)
                            
                            Button(action: {
                                packTitle = suggestion.recommendedTitle
                                packSubject = suggestion.recommendedSubject
                                packType = suggestion.recommendedType.lowercased()
                                rawContent = suggestion.recommendedContent
                            }) {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("Auto-Fill Assignment")
                                }
                                .foregroundColor(Color.theme.accentCyan)
                            }
                        }
                    }
                    
                    Section(header: Text("Raw Content"), footer: Text("Paste the raw text of your document here. Our AI will automatically parse it, structure it, and generate grading rubrics or answer keys depending on the type.")) {
                        Button(action: {
                            showingFileImporter = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Import from file")
                            }
                        }
                        
                        TextEditor(text: $rawContent)
                            .frame(height: 200)
                    }
                    
                    if isUploading {
                        HStack {
                            Spacer()
                            VStack {
                                ProgressView()
                                Text("AI is parsing your document...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                            }
                            Spacer()
                        }
                    } else {
                        Button("Upload & Process") {
                            uploadPack()
                        }
                        .disabled(selectedClassId.isEmpty || packTitle.isEmpty || rawContent.isEmpty)
                    }
                }
                .navigationTitle("New Context Pack")
                .navigationBarItems(trailing: Button("Cancel") {
                    showingUploadModal = false
                })
                .onChange(of: selectedClassId) { _, newValue in
                    fetchSuggestions(for: newValue)
                }
                .fileImporter(
                    isPresented: $showingFileImporter,
                    allowedContentTypes: [.plainText],
                    allowsMultipleSelection: false
                ) { result in
                    do {
                        guard let selectedFile: URL = try result.get().first else { return }
                        if selectedFile.startAccessingSecurityScopedResource() {
                            defer { selectedFile.stopAccessingSecurityScopedResource() }
                            let content = try String(contentsOf: selectedFile, encoding: .utf8)
                            rawContent = content
                        }
                    } catch {
                        errorMessage = "Failed to read file: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func fetchSuggestions(for classId: String) {
        guard !classId.isEmpty else {
            aiSuggestion = nil
            return
        }
        
        isFetchingSuggestion = true
        Task {
            do {
                let progress = try await APIClient.shared.getClassProgress(classId: classId)
                if progress.isEmpty {
                    await MainActor.run {
                        self.isFetchingSuggestion = false
                        self.aiSuggestion = nil
                    }
                    return
                }
                
                let suggestion = try await AIModelService.shared.generateTeacherSuggestion(progress: progress)
                await MainActor.run {
                    self.aiSuggestion = suggestion
                    self.isFetchingSuggestion = false
                }
            } catch {
                print("Failed to fetch suggestions: \(error)")
                await MainActor.run {
                    self.isFetchingSuggestion = false
                }
            }
        }
    }
    
    private func uploadPack() {
        isUploading = true
        Task {
            do {
                let newPack = try await APIClient.shared.createContextPack(
                    classId: selectedClassId,
                    title: packTitle,
                    subject: packSubject,
                    type: packType,
                    rawContent: rawContent
                )
                
                // Register with ClassKit so it's assignable in Schoolwork
                ClassKitManager.shared.registerContextPack(newPack)
                
                await MainActor.run {
                    showingUploadModal = false
                    packTitle = ""
                    rawContent = ""
                    isUploading = false
                    onRefresh()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isUploading = false
                }
            }
        }
    }
}

struct ContextPackCard: View {
    let pack: ContextPackModel
    let className: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(pack.type.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForType(pack.type).opacity(0.2))
                    .foregroundColor(colorForType(pack.type))
                    .cornerRadius(4)
                
                Spacer()
                
                if pack.status == "active" {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Text(pack.title)
                .font(.headline)
                .foregroundColor(.white)
            
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
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type {
        case "lesson": return Color.theme.accentBlue
        case "homework": return Color.theme.accentPurple
        case "quiz": return Color.theme.accentRed
        case "rubric": return Color.theme.accentGreen
        default: return .gray
        }
    }
}
