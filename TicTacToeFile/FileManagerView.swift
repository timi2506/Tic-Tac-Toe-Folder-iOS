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

    var body: some View {
        NavigationView {
            List {
                if files.isEmpty {
                    Text("No file, upload one by tapping the folder icon.")
                } else {
                    ForEach(files, id: \.self) { file in
                        Text(file)
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
                    message: Text("Select an option for \(selectedFile ?? "file")"),
                    buttons: [
                        .default(Text("QuickLook")) { quickLookFile() },
                        .default(Text("Share")) { shareFile() },
                        .default(Text("Rename")) {
                            newFileName = selectedFile ?? ""
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
                    saveFile(url: selectedFileURL)
                    loadFiles()
                }
            case .failure(let error):
                print("Error picking file: \(error)")
            }
        }
    }
    
    private func loadFiles() {
        do {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentDirectory!, includingPropertiesForKeys: nil)
            
            files = fileURLs.map { $0.lastPathComponent }
        } catch {
            print("Error loading files: \(error)")
        }
    }
    
    private func saveFile(url: URL) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentDirectory?.appendingPathComponent(url.lastPathComponent)
        
        do {
            if let destinationURL = destinationURL {
                try FileManager.default.copyItem(at: url, to: destinationURL)
            }
        } catch {
            print("Error saving file: \(error)")
        }
    }

    private func quickLookFile() {
        guard let file = selectedFile else { return }
        temporaryFileURL = copyToTemporaryLocation(fileName: file)
    }
    
    private func shareFile() {
        guard let file = selectedFile else { return }
        let fileURL = copyToTemporaryLocation(fileName: file)
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.presentedViewController?.dismiss(animated: false, completion: nil) // Dismiss any existing modals
            windowScene.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        }
    }
    
    private func copyToTemporaryLocation(fileName: String) -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = documentDirectory?.appendingPathComponent(fileName)
        
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectory.appendingPathComponent(fileName) // Same file name for consistency
        
        // Remove any existing file in the temporary directory with the same name
        if FileManager.default.fileExists(atPath: temporaryFileURL.path) {
            do {
                try FileManager.default.removeItem(at: temporaryFileURL)
            } catch {
                print("Error removing existing temporary file: \(error)")
            }
        }
        
        // Copy the file to the temporary location
        do {
            if let fileURL = fileURL {
                try FileManager.default.copyItem(at: fileURL, to: temporaryFileURL)
            }
        } catch {
            print("Error copying to temporary location: \(error)")
        }
        
        return temporaryFileURL
    }

    private func renameFile() {
        guard let file = selectedFile else { return }
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        guard let oldFileURL = documentDirectory?.appendingPathComponent(file) else { return }
        let newFileURL = documentDirectory?.appendingPathComponent(newFileName)
        
        do {
            if let newFileURL = newFileURL {
                try FileManager.default.moveItem(at: oldFileURL, to: newFileURL)
                loadFiles()
            }
        } catch {
            print("Error renaming file: \(error)")
        }
    }
    
    private func deleteFile() {
        guard let file = selectedFile else { return }
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = documentDirectory?.appendingPathComponent(file)
        
        do {
            if let fileURL = fileURL {
                try FileManager.default.removeItem(at: fileURL)
                loadFiles()
            }
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}

struct FileManagerView_Previews: PreviewProvider {
    static var previews: some View {
        FileManagerView()
    }
}
