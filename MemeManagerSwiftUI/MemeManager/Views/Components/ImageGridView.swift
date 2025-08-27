import SwiftUI
import UniformTypeIdentifiers

struct ImageGridView: View {
    @EnvironmentObject var viewModel: MemeManagerViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppConstants.gridSpacing), count: AppConstants.gridColumns)
    @State private var isDropTargeted = false
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppConstants.gridSpacing) {
                ForEach(viewModel.images) { image in
                    ImageThumbnailView(image: image)
                        .onTapGesture {
                            viewModel.selectedImage = image
                        }
                }
            }
            .padding()
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .overlay(
            // Drop zone overlay when dragging
            isDropTargeted ? 
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: 3)
                .background(Color.accentColor.opacity(0.1))
                .overlay(
                    VStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("Drop images here")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                )
                .padding(20)
            : nil
        )
        .sheet(item: $viewModel.selectedImage) { image in
            ImageDetailView(image: image)
                .environmentObject(viewModel)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                defer { group.leave() }
                
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                // Filter for valid image files
                let imageUrls = urls.filter { url in
                    viewModel.imageProcessingService.validateImageFile(at: url)
                }
                
                if !imageUrls.isEmpty {
                    viewModel.importImages(from: imageUrls)
                } else {
                    viewModel.showError("No valid image files found in dropped items")
                }
            }
        }
        
        return true
    }
}