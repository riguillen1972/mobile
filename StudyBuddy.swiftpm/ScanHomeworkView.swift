import SwiftUI
import PhotosUI

struct ScanHomeworkView: View {
    let displayName: String
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var promptText = "Can you solve this and explain the steps?"
    @State private var isAnalyzing = false
    @State private var resultText = ""
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.theme.mainBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scan Homework")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.theme.textPrimary)
                        Text("Upload a photo of your homework and let our AI tutor break it down.")
                            .font(.body)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    .padding(.top, 16)
                    
                    // Main Card
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Image Picker Area
                        VStack {
                            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                
                                Button("Choose a Different Photo") {
                                    selectedItem = nil
                                    self.selectedImageData = nil
                                }
                                .font(.footnote)
                                .foregroundColor(Color.theme.accentCyan)
                                .padding(.top, 8)
                            } else {
                                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                    VStack(spacing: 16) {
                                        Image(systemName: "camera.viewfinder")
                                            .font(.system(size: 48))
                                            .foregroundColor(Color.theme.accentCyan)
                                        
                                        Text("Select Photo from Library")
                                            .font(.headline)
                                            .foregroundColor(Color.theme.textPrimary)
                                        
                                        Text("JPG, PNG files supported")
                                            .font(.caption)
                                            .foregroundColor(Color.theme.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 48)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.theme.accentCyan.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10]))
                                    )
                                }
                            }
                        }
                        .onChange(of: selectedItem) { oldItem, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                    resultText = ""
                                    errorMessage = ""
                                }
                            }
                        }
                        
                        // Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instructions")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.theme.textSecondary)
                            
                            TextField("What do you want to know about this image?", text: $promptText)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .foregroundColor(Color.theme.textPrimary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                        
                        // Analyze Action Button
                        Button(action: {
                            guard let imageData = selectedImageData, !promptText.isEmpty else { return }
                            isAnalyzing = true
                            errorMessage = ""
                            resultText = ""
                            
                            Task {
                                do {
                                    let result = try await AIModelService.shared.sendMessageWithImage(prompt: promptText, imageData: imageData)
                                    await MainActor.run {
                                        resultText = result
                                        isAnalyzing = false
                                    }
                                } catch {
                                    await MainActor.run {
                                        errorMessage = "Error analyzing image: \\(error.localizedDescription)"
                                        isAnalyzing = false
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isAnalyzing {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Analyze Homework")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color.theme.accentCyan, Color(red: 14/255, green: 165/255, blue: 233/255)], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(selectedImageData == nil || isAnalyzing || promptText.isEmpty)
                        .opacity(selectedImageData == nil ? 0.5 : 1.0)
                        
                        // Output Section
                        if !resultText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Analysis")
                                    .font(.headline)
                                    .foregroundColor(Color.theme.textPrimary)
                                
                                Text(resultText)
                                    .font(.body)
                                    .foregroundColor(Color.theme.textPrimary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.theme.accentCyan.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.theme.accentCyan.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                            .padding(.top, 16)
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.theme.cardBackground.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}
