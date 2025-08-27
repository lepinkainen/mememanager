import SwiftUI
import UniformTypeIdentifiers

// MARK: - Shared Functions
@MainActor
private func openFileDialog(viewModel: MemeManagerViewModel) {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.image]
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    
    if panel.runModal() == .OK {
        viewModel.importImages(from: panel.urls)
    }
}

struct MainView: View {
    @EnvironmentObject var viewModel: MemeManagerViewModel
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    if viewModel.totalImportCount > 0 {
                        ProgressView("Importing images...", value: viewModel.importProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 300)
                        
                        Text("\(viewModel.importingCount) of \(viewModel.totalImportCount) images imported")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ProgressView("Loading...")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.images.isEmpty {
                EmptyStateView()
            } else {
                ImageGridView()
            }
        }
        .padding()
    }
}

struct EmptyStateView: View {
    @EnvironmentObject var viewModel: MemeManagerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Memes Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Drag & drop images here or use the import buttons")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Import Images") {
                    openFileDialog(viewModel: viewModel)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("o", modifiers: .command)
                
                Button("From Clipboard") {
                    viewModel.importFromClipboard()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("v", modifiers: .command)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
