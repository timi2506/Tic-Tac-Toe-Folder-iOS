import SwiftUI
import Intents

@main
struct TicTacToeFileApp: App {
    var body: some Scene {
        WindowGroup {
            TicTacToeView()
                .onOpenURL { url in
                    handleSharedFile(url: url)
                }
        }
    }
    
    // Function to handle saving shared files to the app's document directory
    func handleSharedFile(url: URL) {
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource.")
            return
        }

        // Ensure that we stop accessing the resource when done
        defer {
            url.stopAccessingSecurityScopedResource()
        }

        // Get the app's document directory
        let documentsDirectory = getDocumentsDirectory()
        
        // Create a unique file name in the document directory
        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        
        // Copy the file to the documents directory
        do {
            // If the file already exists, remove it first to avoid overwriting errors
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            print("File saved to: \(destinationURL.path)")
        } catch {
            print("Error saving file: \(error.localizedDescription)")
        }
    }
    
    // Function to retrieve the app's document directory
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
