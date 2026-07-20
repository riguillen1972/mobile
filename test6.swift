import FoundationModels
import Foundation

Task {
    do {
        let session = LanguageModelSession()
        let response = try await session.respond(to: "Tell me a joke.")
        print(response.content)
    } catch {
        print("Error: \(error)")
    }
    exit(0)
}
RunLoop.main.run()
