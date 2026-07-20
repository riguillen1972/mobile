import SwiftUI

struct ClassManagerView: View {
    @Binding var classes: [ClassModel]
    var onRefresh: () -> Void
    
    @State private var showingCreateModal = false
    @State private var newClassName = ""
    @State private var newClassSubject = ""
    @State private var isCreating = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("My Classes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showingCreateModal = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.theme.accentBlue)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(Color.theme.accentRed)
                        .padding(.horizontal)
                }
                
                if classes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.sequence")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No classes yet.")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Create a class to get a join code for your students.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(classes) { cls in
                        ClassCard(cls: cls)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingCreateModal) {
            NavigationView {
                Form {
                    Section(header: Text("Class Details")) {
                        TextField("Class Name (e.g. AP US History)", text: $newClassName)
                        TextField("Subject (Optional)", text: $newClassSubject)
                    }
                    
                    if isCreating {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Button("Create Class") {
                            createClass()
                        }
                        .disabled(newClassName.isEmpty)
                    }
                }
                .navigationTitle("New Class")
                .navigationBarItems(trailing: Button("Cancel") {
                    showingCreateModal = false
                })
            }
        }
    }
    
    private func createClass() {
        isCreating = true
        Task {
            do {
                _ = try await APIClient.shared.createClass(name: newClassName, subject: newClassSubject)
                await MainActor.run {
                    showingCreateModal = false
                    newClassName = ""
                    newClassSubject = ""
                    isCreating = false
                    onRefresh()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isCreating = false
                }
            }
        }
    }
}

struct ClassCard: View {
    let cls: ClassModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cls.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    if let subject = cls.subject, !subject.isEmpty {
                        Text(subject)
                            .font(.subheadline)
                            .foregroundColor(Color.theme.accentBlue)
                    }
                }
                Spacer()
                
                // Join Code
                VStack(alignment: .trailing, spacing: 4) {
                    Text("JOIN CODE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    Text(cls.join_code)
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(Color.theme.accentPurple)
                }
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.gray)
                // We'd parse the enrollments count here if we extended the model
                Text("\(cls.enrollment_count ?? 0) Enrolled Student\((cls.enrollment_count ?? 0) == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = cls.join_code
                }) {
                    Text("Copy Code")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
