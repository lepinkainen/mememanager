import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: MemeManagerViewModel
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
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
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.image]
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    
                    if panel.runModal() == .OK {
                        viewModel.importImages(from: panel.urls)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("From Clipboard") {
                    viewModel.importFromClipboard()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}