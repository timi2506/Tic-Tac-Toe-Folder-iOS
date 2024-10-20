import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct FileManagerView: View {
    @State private var files: [String] = []
    @State private var isPickerPresented = false
    @State private var selectedFile: String?
    @State private var showActionSheet = false
    @State private var showRenameSheet = false
    @State private var newFileName = ""
    @State private var temporaryFileURL: URL?
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    // Store a dictionary to map the encrypted file names to the original ones
    @State private var fileMapping: [String: String] = [:] // [encryptedFileName: originalFileName]

    var body: some View {
        NavigationView {
            VStack {
                List {
                    if files.isEmpty {
                        Text("No file, upload one by tapping the folder icon.")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.clear)
                    } else {
                        ForEach(files, id: \.self) { file in
                            let originalFileName = fileMapping[file] ?? file
                            Text(originalFileName)
                                .onTapGesture {
                                    selectedFile = file
                                    showActionSheet = true
                                }
                        }
                    }
                }
                .navigationTitle("File Manager")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { isPickerPresented = true }) {
                            Image(systemName: "folder.badge.plus")
                        }
                    }
                }
                .actionSheet(isPresented: $showActionSheet) {
                    ActionSheet(
                        title: Text("Choose an action"),
                        message: Text("Select an option for \(fileMapping[selectedFile ?? "file"] ?? "file")"),
                        buttons: [
                            .default(Text("QuickLook")) { quickLookFile() },
                            .default(Text("Share")) { shareFile() },
                            .default(Text("Rename")) {
                                newFileName = fileMapping[selectedFile ?? ""] ?? selectedFile ?? ""
                                showRenameSheet = true
                            },
                            .destructive(Text("Delete")) { deleteFile() },
                            .cancel()
                        ]
                    )
                }
                .sheet(isPresented: $showRenameSheet) {
                    VStack(spacing: 20) {
                        Text("Rename File")
                            .font(.headline)
                        TextField("New File Name", text: $newFileName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        HStack {
                            Button("Cancel") {
                                showRenameSheet = false
                            }
                            .foregroundColor(.red)
                            Spacer()
                            Button("Save") {
                                renameFile()
                                showRenameSheet = false
                            }
                            .foregroundColor(.blue)
                        }
                        .padding()
                    }
                    .padding()
                }
                .quickLookPreview($temporaryFileURL)
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: shareItems)
                }
                
                // Drop area at the bottom of the screen
                dropArea
                    .padding()
            }
            .onAppear {
                loadFiles()
            }
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let selectedFileURL = urls.first {
                        handleFile(selectedFileURL)
                    }
                case .failure(let error):
                    print("Error picking file: \(error)")
                }
            }
        }
    }
    
    private var dropArea: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 100)
            .cornerRadius(10) // Add rounded corners
            .overlay(
                Text("Drop files here")
                    .foregroundColor(Color(UIColor.label)) // Adjust color based on light/dark mode
            )
            .onDrop(of: [UTType.item, UTType.application], isTargeted: nil) { providers in
                for provider in providers {
                    // Load the dropped item
                    provider.loadItem(forTypeIdentifier: UTType.item.identifier) { (item, error) in
                        if let url = item as? URL {
                            handleFile(url)
                        }
                    }
                }
                return true
            }
    }
    
    private func handleFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("Could not access the security scoped resource.")
            return
        }
        
        // Call saveFile after successfully accessing the resource
        saveFile(url: url)
        loadFiles()
        
        // Stop accessing the resource
        url.stopAccessingSecurityScopedResource()
    }

    // Encrypt the file and map the original name to the encrypted one
    private func saveFile(url: URL) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        // Generate a random encrypted name and extension
        let encryptedFileName = UUID().uuidString
        let encryptedFileURL = documentDirectory?.appendingPathComponent(encryptedFileName)
        
        do {
            // Encrypt the file (for simplicity, copying it with a new name here)
            if let encryptedFileURL = encryptedFileURL {
                try FileManager.default.copyItem(at: url, to: encryptedFileURL)
                // Map encrypted name to original name
                fileMapping[encryptedFileName] = url.lastPathComponent
                saveMapping()  // Save the mapping persistently
            }
        } catch {
            print("Error saving file: \(error)")
        }
    }
    
    // Save the file mapping to persist it across app launches
    private func saveMapping() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(fileMapping, forKey: "fileMapping")
    }
    
    // Load the files and the mapping between encrypted and original names
    private func loadFiles() {
        do {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentDirectory!, includingPropertiesForKeys: nil)
            
            files = fileURLs.map { $0.lastPathComponent }
            
            // Load the file mapping (persistent storage)
            let userDefaults = UserDefaults.standard
            if let savedMapping = userDefaults.dictionary(forKey: "fileMapping") as? [String: String] {
                fileMapping = savedMapping
            }
        } catch {
            print("Error loading files: \(error)")
        }
    }

    // Perform QuickLook after restoring the original file name
    private func quickLookFile() {
        guard let file = selectedFile, let originalFileName = fileMapping[file] else { return }
        temporaryFileURL = copyToTemporaryLocation(encryptedFileName: file, originalFileName: originalFileName)
    }
    
    // Share the file after restoring the original name
    private func shareFile() {
        guard let file = selectedFile, let originalFileName = fileMapping[file] else { return }
        let fileURL = copyToTemporaryLocation(encryptedFileName: file, originalFileName: originalFileName)
        
        shareItems = [fileURL]
        showShareSheet = true
    }
    
    
    // Decrypt or copy the file to a temporary location with the original name
    private func copyToTemporaryLocation(encryptedFileName: String, originalFileName: String) -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let encryptedFileURL = documentDirectory?.appendingPathComponent(encryptedFileName)
        
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectory.appendingPathComponent(originalFileName) // Restore the original name
        
        // Remove any existing file in the temporary directory with the same name
        if FileManager.default.fileExists(atPath: temporaryFileURL.path) {
            do {
                try FileManager.default.removeItem(at: temporaryFileURL)
            } catch {
                print("Error removing existing temporary file: \(error)")
            }
        }
        
        // Copy the encrypted file back to its original name for use
        do {
            if let encryptedFileURL = encryptedFileURL {
                try FileManager.default.copyItem(at: encryptedFileURL, to: temporaryFileURL)
            }
        } catch {
            print("Error copying to temporary location: \(error)")
        }
        
        return temporaryFileURL
    }
    
    private func deleteFile() {
        guard let fileToDelete = selectedFile else { return }
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = documentDirectory?.appendingPathComponent(fileToDelete)
        
        do {
            if let fileURL = fileURL {
                try FileManager.default.removeItem(at: fileURL)
                files.removeAll { $0 == fileToDelete }
                fileMapping.removeValue(forKey: fileToDelete)
                saveMapping() // Update the mapping
                loadFiles() // Refresh the file list
            }
        } catch {
            print("Error deleting file: \(error)")
        }
    }
    
    private func renameFile() {
        guard let fileToRename = selectedFile else { return }
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = documentDirectory?.appendingPathComponent(fileToRename)
        
        let newFileName = newFileName.isEmpty ? fileMapping[fileToRename] ?? fileToRename : newFileName
        let newFileURL = documentDirectory?.appendingPathComponent(newFileName)
        
        do {
            if let fileURL = fileURL, let newFileURL = newFileURL {
                try FileManager.default.moveItem(at: fileURL, to: newFileURL)
                if let originalName = fileMapping[fileToRename] {
                    fileMapping[newFileName] = originalName
                    fileMapping.removeValue(forKey: fileToRename)
                    saveMapping() // Update the mapping
                }
                loadFiles() // Refresh the file list
            }
        } catch {
            print("Error renaming file: \(error)")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}
