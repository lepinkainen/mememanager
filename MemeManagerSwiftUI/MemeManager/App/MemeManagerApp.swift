import SwiftUI
import AppKit

@main
struct MemeManagerApp: App {
    @StateObject private var viewModel = MemeManagerViewModel()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .environmentObject(viewModel)
                .onAppear {
                    // Set up the app as a regular application with menu bar presence
                    DispatchQueue.main.async {
                        NSApp.setActivationPolicy(.regular)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import Images...") {
                    showImportDialog()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Import from Clipboard") {
                    viewModel.importFromClipboard()
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
                .disabled(!viewModel.hasClipboardImage())
            }
            
            CommandGroup(after: .pasteboard) {
                Divider()
                
                Button("Copy Selected Image") {
                    if let selectedImage = viewModel.selectedImage {
                        viewModel.copyImageToClipboard(selectedImage)
                    }
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(viewModel.selectedImage == nil)
                
                Button("Delete Selected Image") {
                    if let selectedImage = viewModel.selectedImage {
                        viewModel.deleteImage(selectedImage)
                        viewModel.clearSelectedImage()
                    }
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(viewModel.selectedImage == nil)
                
                Button("Show in Finder") {
                    if let selectedImage = viewModel.selectedImage {
                        viewModel.showImageInFinder(selectedImage)
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(viewModel.selectedImage == nil)
            }
            
            CommandGroup(before: .sidebar) {
                Button("Clear Search & Filters") {
                    viewModel.clearFilters()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                
                Button("Refresh") {
                    viewModel.loadInitialData()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Divider()
            }
        }
    }
    
    private func showImportDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.title = "Import Meme Images"
        panel.message = "Select images to add to your meme collection"
        
        if panel.runModal() == .OK {
            viewModel.importImages(from: panel.urls)
        }
    }
}