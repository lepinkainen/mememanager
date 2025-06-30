import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var viewModel: MemeManagerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Import Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Import")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    Button(action: {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [.image]
                        panel.allowsMultipleSelection = true
                        panel.canChooseDirectories = false
                        panel.canChooseFiles = true
                        
                        if panel.runModal() == .OK {
                            viewModel.importImages(from: panel.urls)
                        }
                    }) {
                        Label("Import Images", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.large)
                    .help("Select images from your computer to import")
                    
                    Button(action: {
                        viewModel.importFromClipboard()
                    }) {
                        Label("From Clipboard", systemImage: "doc.on.clipboard")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.large)
                    .help("Import image from clipboard (⌘⇧V)")
                }
            }
            
            Divider()
            
            // Search Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Search")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !viewModel.searchText.isEmpty || !viewModel.selectedTags.isEmpty {
                        Button("Clear") {
                            viewModel.clearFilters()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .buttonStyle(.borderless)
                        .help("Clear all search filters (ESC)")
                    }
                }
                
                SearchBar()
                
                // Tag filters
                if !viewModel.allTags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Filter by Tags")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 70), spacing: 6)
                        ], spacing: 6) {
                            ForEach(viewModel.allTags, id: \.id) { tag in
                                FilterTagChip(
                                    tag: tag,
                                    isSelected: viewModel.selectedTags.contains(tag.name)
                                ) {
                                    viewModel.toggleTagFilter(tag.name)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Stats
            if !viewModel.images.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.images.count)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("memes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(viewModel.allTags.count)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("tags")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 220)
    }
}

struct SearchBar: View {
    @EnvironmentObject var viewModel: MemeManagerViewModel
    
    var body: some View {
        TextField("Search memes...", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
            .help("Search by image name or content")
    }
}

struct FilterTagChip: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.4), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}