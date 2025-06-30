import Foundation
import AppKit

class ImageProcessingService {
    static let shared = ImageProcessingService()
    
    private init() {}
    
    func generateThumbnail(from imagePath: String) -> NSImage? {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            return nil
        }
        
        let thumbnailSize = AppConstants.thumbnailSize
        let thumbnail = NSImage(size: thumbnailSize)
        
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbnailSize))
        thumbnail.unlockFocus()
        
        return thumbnail
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
        let fileExtension = url.pathExtension.lowercased()
        return AppConstants.supportedImageTypes.contains(fileExtension)
    }
}