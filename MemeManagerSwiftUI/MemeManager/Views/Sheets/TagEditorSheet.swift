import SwiftUI

struct TagEditorSheet: View {
    let image: MemeImage
    @EnvironmentObject var viewModel: MemeManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newTagText = ""
    @State private var currentTags: [String] = []
    @FocusState private var isTextFieldFocused: Bool
    
    var suggestedTags: [String] {
        let allTags = viewModel.images.flatMap { $0.tags.map { $0.name } }
        let uniqueTags = Array(Set(allTags)).sorted()
        let currentTagNames = Set(currentTags)
        return uniqueTags.filter { !currentTagNames.contains($0) && $0.localizedCaseInsensitiveContains(newTagText) }
    }
    
    var parsedTags: [String] {
        guard !newTagText.isEmpty else { return [] }
        return newTagText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Tags")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Add tags to organize and find your memes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Current tags
                        if !image.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Tags")
                                    .font(.headline)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 80), spacing: 8)
                                ], spacing: 8) {
                                    ForEach(image.tags, id: \.id) { tag in
                                        HStack(spacing: 6) {
                                            Text(tag.name)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                            
                                            Button(action: {
                                                viewModel.removeTagFromImage(image, tag: tag)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Add new tags section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add New Tags")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Enter tags separated by commas", text: $newTagText)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($isTextFieldFocused)
                                    .onSubmit {
                                        addTags()
                                    }
                                
                                Text("Separate multiple tags with commas")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Live preview of tags being typed
                            if !parsedTags.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Preview")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.adaptive(minimum: 80), spacing: 8)
                                    ], spacing: 8) {
                                        ForEach(parsedTags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.green.opacity(0.15))
                                                .foregroundColor(.green)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.green.opacity(0.3), lineWidth: 0.5)
                                                )
                                        }
                                    }
                                }
                            }
                            
                            // Suggested tags
                            if !suggestedTags.isEmpty && !newTagText.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Suggestions")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.adaptive(minimum: 80), spacing: 8)
                                    ], spacing: 8) {
                                        ForEach(suggestedTags.prefix(10), id: \.self) { tag in
                                            Button(action: {
                                                addSuggestedTag(tag)
                                            }) {
                                                Text(tag)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.gray.opacity(0.15))
                                                    .foregroundColor(.primary)
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Bottom buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)
                    
                    Spacer()
                    
                    Button("Add Tags") {
                        addTags()
                        dismiss()
                    }
                    .keyboardShortcut(.return)
                    .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func addTags() {
        let tagNames = parsedTags
        if !tagNames.isEmpty {
            viewModel.addTagsToImage(image, tagNames: tagNames)
            newTagText = ""
        }
    }
    
    private func addSuggestedTag(_ tag: String) {
        if newTagText.isEmpty {
            newTagText = tag
        } else {
            newTagText += ", " + tag
        }
    }
}