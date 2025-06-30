import SwiftUI

struct ImageGridView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppConstants.gridSpacing), count: AppConstants.gridColumns)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppConstants.gridSpacing) {
                // TODO: Replace with actual image data
                ForEach(0..<10, id: \.self) { index in
                    ImageThumbnailView(imageName: "Placeholder \(index)")
                }
            }
            .padding()
        }
    }
}