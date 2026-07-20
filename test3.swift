import FoundationModels
import Foundation

Task {
    do {
        let session = LanguageModelSession()
        let response = try await session.respond(to: "Hello")
        print("Model replied: \(response.text)")
    } catch {
        print("Error: \(error)")
    }
    exit(0)
}
RunLoop.main.run()
