import SwiftUI

struct MainView: View {
    var body: some View {
        VStack {
            if true { // TODO: Replace with actual data check
                EmptyStateView()
            } else {
                ImageGridView()
            }
        }
        .padding()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Memes Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Import some images to get started")
                .foregroundColor(.secondary)
            
            Button(action: {
                // TODO: Implement import
            }) {
                Text("Import Images")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}