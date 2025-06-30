import SwiftUI

struct ImageThumbnailView: View {
    let image: MemeImage
    @EnvironmentObject var viewModel: MemeManagerViewModel
    @State private var showingRenameAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var newName = ""
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(fileURLWithPath: image.path)) { phase in
                switch phase {
                case .success(let loadedImage):
                    loadedImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: AppConstants.thumbnailSize.width, height: AppConstants.thumbnailSize.height)
                        .clipped()
                        .cornerRadius(8)
                case .failure(_):
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.3))
                        .frame(width: AppConstants.thumbnailSize.width, height: AppConstants.thumbnailSize.height)
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                        )
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: AppConstants.thumbnailSize.width, height: AppConstants.thumbnailSize.height)
                        .overlay(
                            ProgressView()
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(spacing: 2) {
                Text(image.originalName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if !image.tags.isEmpty {
                    HStack {
                        ForEach(image.tags.prefix(3), id: \.id) { tag in
                            Text(tag.name)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        if image.tags.count > 3 {
                            Text("+\(image.tags.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(width: AppConstants.thumbnailSize.width)
        }
        .contextMenu {
            Button("Copy to Clipboard") {
                viewModel.copyImageToClipboard(image)
            }
            
            Button("Show in Finder") {
                viewModel.showImageInFinder(image)
            }
            
            Divider()
            
            Button("Rename") {
                newName = image.originalName
                showingRenameAlert = true
            }
            
            Button("Edit Tags...") {
                viewModel.selectedImage = image
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                showingDeleteConfirmation = true
            }
        }
        .alert("Rename Image", isPresented: $showingRenameAlert) {
            TextField("New name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                viewModel.renameImage(image, newName: newName.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        .alert("Delete Image", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteImage(image)
            }
        } message: {
            Text("Are you sure you want to delete \"\(image.originalName)\"? This action cannot be undone.")
        }
    }
}