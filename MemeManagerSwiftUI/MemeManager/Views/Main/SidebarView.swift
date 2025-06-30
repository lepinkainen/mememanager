import SwiftUI

struct SidebarView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Import Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Import")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // TODO: Implement file import
                }) {
                    Label("Import Images", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    // TODO: Implement clipboard import
                }) {
                    Label("From Clipboard", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Search Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Search")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                SearchBar()
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 200)
    }
}

struct SearchBar: View {
    @State private var searchText = ""
    
    var body: some View {
        TextField("Search memes...", text: $searchText)
            .textFieldStyle(.roundedBorder)
    }
}