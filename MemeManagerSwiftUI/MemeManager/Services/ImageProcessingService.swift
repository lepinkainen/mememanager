import Foundation
import AppKit
import UniformTypeIdentifiers
import CoreGraphics

struct ImageInfo {
    let size: CGSize
    let fileSize: Int64
    let type: UTType
}

class ImageProcessingService: ObservableObject {
    static let shared = ImageProcessingService()
    
    static let thumbnailSize = CGSize(width: 200, height: 200)
    static let maxImageSize = CGSize(width: 2048, height: 2048)
    static let supportedTypes: [UTType] = [.png, .jpeg, .gif, .bmp]
    
    private let fileManager: FileManagerService
    
    private init() {
        self.fileManager = FileManagerService.shared
    }
    
    // MARK: - Image Processing
    func createThumbnail(from imageURL: URL) async -> NSImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let image = NSImage(contentsOf: imageURL) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let thumbnail = self.resizeImage(image, to: Self.thumbnailSize)
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    private func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .sourceOver,
                   fraction: 1.0)
        
        return newImage
    }
    
    func optimizeImage(_ image: NSImage) -> NSImage {
        guard image.size.width > Self.maxImageSize.width ||
              image.size.height > Self.maxImageSize.height else {
            return image
        }
        
        let aspectRatio = image.size.width / image.size.height
        var newSize = Self.maxImageSize
        
        if aspectRatio > 1 {
            newSize.height = newSize.width / aspectRatio
        } else {
            newSize.width = newSize.height * aspectRatio
        }
        
        return resizeImage(image, to: newSize)
    }
    
    // MARK: - File Validation
    func isSupportedImageType(_ url: URL) -> Bool {
        guard let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }
        
        return Self.supportedTypes.contains { supportedType in
            contentType.conforms(to: supportedType)
        }
    }
    
    func validateImageFile(at url: URL) -> Bool {
        guard url.isFileURL && isSupportedImageType(url) else { return false }
        
        // Try to load the image to verify it's valid
        return NSImage(contentsOf: url) != nil
    }
    
    // MARK: - Image Information
    func getImageInfo(from url: URL) -> ImageInfo? {
        guard let image = NSImage(contentsOf: url) else { return nil }
        
        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
        let fileSize = resourceValues?.fileSize ?? 0
        let contentType = resourceValues?.contentType ?? UTType.image
        
        return ImageInfo(
            size: image.size,
            fileSize: Int64(fileSize),
            type: contentType
        )
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    func generateThumbnail(from imagePath: String) -> NSImage? {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            return nil
        }
        
        return resizeImage(image, to: AppConstants.thumbnailSize)
    }
    
    func saveThumbnail(_ thumbnail: NSImage, to path: String) -> Bool {
        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImageRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            return false
        }
        
        do {
            try jpegData.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            print("Error saving thumbnail: \(error)")
            return false
        }
    }
    
    func isValidImageFile(_ url: URL) -> Bool {
        return validateImageFile(at: url)
    }
}