import SwiftUI

struct ImageGridView: View {
    @EnvironmentObject var viewModel: MemeManagerViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppConstants.gridSpacing), count: AppConstants.gridColumns)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppConstants.gridSpacing) {
                ForEach(viewModel.images) { image in
                    ImageThumbnailView(image: image)
                        .onTapGesture {
                            viewModel.selectedImage = image
                        }
                }
            }
            .padding()
        }
        .sheet(item: $viewModel.selectedImage) { image in
            ImageDetailView(image: image)
                .environmentObject(viewModel)
        }
    }
}