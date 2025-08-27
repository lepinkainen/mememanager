import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
class MemeManagerViewModel: ObservableObject {
    @Published var images: [MemeImage] = []
    @Published var searchText: String = ""
    @Published var selectedTags: Set<String> = []
    @Published var allTags: [Tag] = []
    @Published var isLoading: Bool = false
    @Published var selectedImage: MemeImage?
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    @Published var successMessage: String?
    @Published var showingSuccess: Bool = false
    @Published var importProgress: Double = 0.0
    @Published var importingCount: Int = 0
    @Published var totalImportCount: Int = 0
    
    private let databaseService = DatabaseService.shared
    private let fileManagerService = FileManagerService.shared
    let imageProcessingService = ImageProcessingService.shared
    private let clipboardService = ClipboardService()
    private lazy var thumbnailManager = ThumbnailManager(
        imageProcessor: imageProcessingService,
        fileManager: fileManagerService
    )
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearchSubscription()
        loadInitialData()
    }
    
    private func setupSearchSubscription() {
        Publishers.CombineLatest($searchText, $selectedTags)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText, selectedTags in
                self?.performSearch(text: searchText, tags: Array(selectedTags))
            }
            .store(in: &cancellables)
    }
    
    func loadInitialData() {
        isLoading = true
        
        Task {
            images = databaseService.getAllImages()
            allTags = databaseService.getAllTags()
            isLoading = false
        }
    }
    
    private func performSearch(text: String, tags: [String]) {
        isLoading = true
        
        Task {
            if text.isEmpty && tags.isEmpty {
                images = databaseService.getAllImages()
            } else {
                images = databaseService.searchImagesWithTextAndTags(textQuery: text, tagNames: tags)
            }
            isLoading = false
        }
    }
    
    func importImages(from urls: [URL]) {
        // Filter valid image URLs
        let validUrls = urls.filter { url in
            let fileExtension = url.pathExtension.lowercased()
            return AppConstants.supportedImageTypes.contains(fileExtension)
        }
        
        let skippedCount = urls.count - validUrls.count
        if skippedCount > 0 {
            showError("Skipped \(skippedCount) unsupported file\(skippedCount == 1 ? "" : "s")")
        }
        
        guard !validUrls.isEmpty else {
            showError("No supported image files found")
            return
        }
        
        isLoading = true
        totalImportCount = validUrls.count
        importingCount = 0
        importProgress = 0.0
        
        Task {
            for (index, url) in validUrls.enumerated() {
                await importSingleImage(from: url)
                importingCount = index + 1
                importProgress = Double(importingCount) / Double(totalImportCount)
            }
            
            importProgress = 1.0
            showSuccess("Imported \(validUrls.count) image\(validUrls.count == 1 ? "" : "s") successfully")
            loadInitialData()
            
            // Reset progress after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.importProgress = 0.0
                self.importingCount = 0
                self.totalImportCount = 0
            }
        }
    }
    
    private func importSingleImage(from url: URL) async {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let originalName = url.lastPathComponent
        
        guard let savedPath = fileManagerService.saveImage(from: url, originalName: originalName) else {
            print("Failed to save image: \(originalName)")
            return
        }
        
        let now = Date()
        let newImage = MemeImage(
            databaseId: nil,
            filename: URL(fileURLWithPath: savedPath).lastPathComponent,
            originalName: originalName,
            path: savedPath,
            createdDate: now,
            updatedDate: now
        )
        
        _ = databaseService.createImage(newImage)
    }
    
    func importFromClipboard() {
        guard let image = clipboardService.getImageFromClipboard() else {
            showError("No image found in clipboard")
            return
        }
        
        isLoading = true
        updateStatus("Importing image from clipboard...")
        
        Task {
            if let tempURL = await saveImageToTemp(image: image) {
                await importSingleImage(from: tempURL)
                try? FileManager.default.removeItem(at: tempURL)
                await MainActor.run {
                    showSuccess("Image imported from clipboard")
                    loadInitialData()
                }
            } else {
                await MainActor.run {
                    showError("Failed to process clipboard image")
                    isLoading = false
                }
            }
        }
    }
    
    func hasClipboardImage() -> Bool {
        return clipboardService.hasImageInClipboard()
    }
    
    private func saveImageToTemp(image: NSImage) async -> URL? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        
        do {
            try pngData.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save temp image: \(error)")
            return nil
        }
    }
    
    func copyImageToClipboard(_ image: MemeImage) {
        Task {
            let success = clipboardService.copyImageFileToClipboard(from: URL(fileURLWithPath: image.path))
            
            await MainActor.run {
                if success {
                    showSuccess("Image copied to clipboard")
                } else {
                    showError("Failed to copy image to clipboard")
                }
            }
        }
    }
    
    func deleteImage(_ image: MemeImage) {
        guard let imageId = image.databaseId else { 
            showError("Cannot delete image: Invalid image ID")
            return 
        }
        
        if databaseService.deleteImage(id: imageId) {
            try? FileManager.default.removeItem(atPath: image.path)
            showSuccess("Image deleted successfully")
            loadInitialData()
        } else {
            showError("Failed to delete image")
        }
    }
    
    func addTagsToImage(_ image: MemeImage, tagNames: [String]) {
        guard let imageId = image.databaseId else { 
            showError("Cannot add tags: Invalid image ID")
            return 
        }
        
        let validTags = tagNames.filter { !$0.isEmpty }
        guard !validTags.isEmpty else {
            showError("No valid tags to add")
            return
        }
        
        if databaseService.addTagsToImage(imageId: imageId, tagNames: validTags) {
            showSuccess("Tags added successfully")
            loadInitialData()
        } else {
            showError("Failed to add tags")
        }
    }
    
    func removeTagFromImage(_ image: MemeImage, tag: Tag) {
        guard let imageId = image.databaseId else { 
            showError("Cannot remove tag: Invalid image ID")
            return 
        }
        
        if databaseService.removeTagFromImage(imageId: imageId, tagId: tag.id) {
            showSuccess("Tag removed successfully")
            loadInitialData()
        } else {
            showError("Failed to remove tag")
        }
    }
    
    func toggleTagFilter(_ tagName: String) {
        if selectedTags.contains(tagName) {
            selectedTags.remove(tagName)
        } else {
            selectedTags.insert(tagName)
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedTags.removeAll()
    }
    
    func clearSelectedImage() {
        selectedImage = nil
    }
    
    func renameImage(_ image: MemeImage, newName: String) {
        guard let imageId = image.databaseId else { 
            showError("Cannot rename image: Invalid image ID")
            return 
        }
        
        guard !newName.isEmpty else {
            showError("Image name cannot be empty")
            return
        }
        
        if databaseService.updateImageName(id: imageId, newName: newName) {
            showSuccess("Image renamed successfully")
            loadInitialData()
        } else {
            showError("Failed to rename image")
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func showSuccess(_ message: String) {
        successMessage = message
        showingSuccess = true
    }
    
    private func updateStatus(_ message: String) {
        // For now, we'll use success messages for status updates
        // In a future version, we could add a dedicated status system
        showSuccess(message)
    }
    
    func showImageInFinder(_ image: MemeImage) {
        let url = URL(fileURLWithPath: image.path)
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
}