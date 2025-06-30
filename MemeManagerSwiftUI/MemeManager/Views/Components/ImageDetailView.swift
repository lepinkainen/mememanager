import SwiftUI

struct ImageDetailView: View {
    let image: MemeImage
    @EnvironmentObject var viewModel: MemeManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newTagText = ""
    @State private var showingTagInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Image preview
                AsyncImage(url: URL(fileURLWithPath: image.path)) { phase in
                    switch phase {
                    case .success(let loadedImage):
                        loadedImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .cornerRadius(12)
                    case .failure(_):
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 32))
                                        .foregroundColor(.red)
                                    Text("Failed to load image")
                                        .foregroundColor(.red)
                                }
                            )
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(ProgressView())
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Image details
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(image.originalName)
                                .font(.headline)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Created")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(image.createdDate, style: .date)
                                .font(.subheadline)
                        }
                    }
                    
                    Divider()
                    
                    // Tags section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tags")
                                .font(.headline)
                            Spacer()
                            Button(action: { showingTagInput = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if image.tags.isEmpty {
                            Text("No tags")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80), spacing: 8)
                            ], spacing: 8) {
                                ForEach(image.tags, id: \.id) { tag in
                                    TagChip(tag: tag) {
                                        viewModel.removeTagFromImage(image, tag: tag)
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Copy to Clipboard") {
                        viewModel.copyImageToClipboard(image)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Delete", role: .destructive) {
                        viewModel.deleteImage(image)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Image Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Add Tags", isPresented: $showingTagInput) {
            TextField("Enter tags (comma separated)", text: $newTagText)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                let tagNames = newTagText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                viewModel.addTagsToImage(image, tagNames: tagNames)
                newTagText = ""
                dismiss()
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct TagChip: View {
    let tag: Tag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}