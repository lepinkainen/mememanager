import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var viewModel: MemeManagerViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Import Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Import")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
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
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    viewModel.importFromClipboard()
                }) {
                    Label("From Clipboard", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Search Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Search")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !viewModel.searchText.isEmpty || !viewModel.selectedTags.isEmpty {
                        Button("Clear") {
                            viewModel.clearFilters()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                
                SearchBar()
                
                // Tag filters
                if !viewModel.allTags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filter by Tags")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 60), spacing: 4)
                        ], spacing: 4) {
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
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    Text("\(viewModel.images.count) memes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.allTags.count) tags")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}