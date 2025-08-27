import AppKit
import Foundation

actor ThumbnailCache {
    private var cache: [String: NSImage] = [:]
    private let maxCacheSize = 100 // Maximum cached thumbnails
    
    func getThumbnail(for key: String) -> NSImage? {
        return cache[key]
    }
    
    func setThumbnail(_ image: NSImage, for key: String) {
        if cache.count >= maxCacheSize {
            // Remove oldest entries (simple FIFO)
            let keysToRemove = Array(cache.keys.prefix(10))
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
        cache[key] = image
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

@MainActor
class ThumbnailManager: ObservableObject {
    private let cache = ThumbnailCache()
    private let imageProcessor: ImageProcessingService
    private let fileManager: FileManagerService
    
    init(imageProcessor: ImageProcessingService, fileManager: FileManagerService) {
        self.imageProcessor = imageProcessor
        self.fileManager = fileManager
    }
    
    func getThumbnail(for image: MemeImage) async -> NSImage? {
        let cacheKey = image.filename
        
        // Check cache first
        if let cachedThumbnail = await cache.getThumbnail(for: cacheKey) {
            return cachedThumbnail
        }
        
        // Check if thumbnail file exists
        let thumbnailPath = fileManager.getThumbnailPath(for: image)
        if FileManager.default.fileExists(atPath: thumbnailPath.path) {
            if let thumbnail = NSImage(contentsOf: thumbnailPath) {
                await cache.setThumbnail(thumbnail, for: cacheKey)
                return thumbnail
            }
        }
        
        // Generate new thumbnail
        guard let imageURL = URL(string: "file://" + image.path) else { return nil }
        
        if let thumbnail = await imageProcessor.createThumbnail(from: imageURL) {
            // Save thumbnail to disk
            saveThumbnailToDisk(thumbnail, at: thumbnailPath)
            
            // Cache in memory
            await cache.setThumbnail(thumbnail, for: cacheKey)
            
            return thumbnail
        }
        
        return nil
    }
    
    private func saveThumbnailToDisk(_ image: NSImage, at url: URL) {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            return
        }
        
        // Ensure directory exists
        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        try? jpegData.write(to: url)
    }
    
    func clearCache() async {
        await cache.clearCache()
    }
    
    func deleteThumbnail(for image: MemeImage) {
        let thumbnailPath = fileManager.getThumbnailPath(for: image)
        try? FileManager.default.removeItem(at: thumbnailPath)
    }
}