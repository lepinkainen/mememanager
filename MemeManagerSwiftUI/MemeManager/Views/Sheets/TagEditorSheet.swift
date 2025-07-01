import SwiftUI

struct TagEditorSheet: View {
    let image: MemeImage
    @EnvironmentObject var viewModel: MemeManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newTagText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var suggestedTags: [String] {
        let allTags = viewModel.images.flatMap { $0.tags.map { $0.name } }
        let uniqueTags = Array(Set(allTags)).sorted()
        let currentTagNames = Set(image.tags.map { $0.name })
        return uniqueTags.filter { !currentTagNames.contains($0) && $0.localizedCaseInsensitiveContains(newTagText) }
    }
    
    var parsedTags: [String] {
        guard !newTagText.isEmpty else { return [] }
        return newTagText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Add Tags")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
            
            // Current tags display
            if !image.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Tags:")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(image.tags, id: \.id) { tag in
                                HStack(spacing: 4) {
                                    Text(tag.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Button(action: {
                                        viewModel.removeTagFromImage(image, tag: tag)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            }
            
            // Simple text input - back to regular SwiftUI TextField
            VStack(alignment: .leading, spacing: 8) {
                Text("New Tags (comma separated):")
                    .font(.headline)
                
                TextField("Enter tags separated by commas...", text: $newTagText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        addTags()
                        dismiss()
                    }
            }
            .padding(.horizontal)
            
            // Preview tags
            if !parsedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(parsedTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            }
            
            // Suggestions
            if !suggestedTags.isEmpty && !newTagText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedTags.prefix(8), id: \.self) { tag in
                                Button(action: {
                                    addSuggestedTag(tag)
                                }) {
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            }
            
            // Action buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("Add Tags") {
                    addTags()
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            
            Spacer()
        }
        .frame(minWidth: 500, minHeight: 350)
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
