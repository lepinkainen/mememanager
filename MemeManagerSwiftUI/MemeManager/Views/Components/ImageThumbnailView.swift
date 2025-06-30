import SwiftUI

struct ImageThumbnailView: View {
    let imageName: String
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: AppConstants.thumbnailSize.width, height: AppConstants.thumbnailSize.height)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                )
            
            Text(imageName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .contextMenu {
            Button("Copy") {
                // TODO: Implement copy to clipboard
            }
            Button("Rename") {
                // TODO: Implement rename
            }
            Button("Delete") {
                // TODO: Implement delete
            }
        }
    }
}