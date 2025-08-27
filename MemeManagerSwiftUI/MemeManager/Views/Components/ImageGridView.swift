import SwiftUI
import UniformTypeIdentifiers

struct ImageGridView: View {
    @EnvironmentObject var viewModel: MemeManagerViewModel
    @State private var isDropTargeted = false
    @State private var containerWidth: CGFloat = 0
    
    private var adaptiveColumns: [GridItem] {
        let minColumnWidth: CGFloat = AppConstants.thumbnailSize.width + AppConstants.gridSpacing
        let maxColumns = max(1, Int(containerWidth / minColumnWidth))
        let columnCount = min(maxColumns, 6) // Maximum 6 columns
        return Array(repeating: GridItem(.flexible(), spacing: AppConstants.gridSpacing), count: columnCount)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: adaptiveColumns, spacing: AppConstants.gridSpacing) {
                ForEach(viewModel.images) { image in
                    ImageThumbnailView(image: image)
                        .onTapGesture {
                            viewModel.selectedImage = image
                        }
                        .onAppear {
                            // Load more images when reaching the last 10 items
                            if let lastImage = viewModel.images.last,
                               image.id == lastImage.id,
                               viewModel.images.count >= 10 {
                                viewModel.loadMoreImages()
                            }
                        }
                }
                
                // Loading indicator for pagination
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Loading more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                }
                }
                .padding()
                .onAppear {
                    containerWidth = geometry.size.width - 40 // Account for padding
                }
                .onChange(of: geometry.size.width) { _, newWidth in
                    containerWidth = newWidth - 40 // Account for padding
                }
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