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
    
    private let databaseService = DatabaseService.shared
    private let fileManagerService = FileManagerService.shared
    private let imageProcessingService = ImageProcessingService.shared
    
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
        isLoading = true
        
        Task {
            for url in urls {
                await importSingleImage(from: url)
            }
            loadInitialData()
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
        guard let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage else {
            return
        }
        
        isLoading = true
        
        Task {
            if let tempURL = await saveImageToTemp(image: image) {
                await importSingleImage(from: tempURL)
                try? FileManager.default.removeItem(at: tempURL)
                loadInitialData()
            }
        }
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
        guard let nsImage = NSImage(contentsOfFile: image.path) else { return }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([nsImage])
    }
    
    func deleteImage(_ image: MemeImage) {
        guard let imageId = image.databaseId else { return }
        
        if databaseService.deleteImage(id: imageId) {
            try? FileManager.default.removeItem(atPath: image.path)
            loadInitialData()
        }
    }
    
    func addTagsToImage(_ image: MemeImage, tagNames: [String]) {
        guard let imageId = image.databaseId else { return }
        
        if databaseService.addTagsToImage(imageId: imageId, tagNames: tagNames) {
            loadInitialData()
        }
    }
    
    func removeTagFromImage(_ image: MemeImage, tag: Tag) {
        guard let imageId = image.databaseId else { return }
        
        if databaseService.removeTagFromImage(imageId: imageId, tagId: tag.id) {
            loadInitialData()
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
}