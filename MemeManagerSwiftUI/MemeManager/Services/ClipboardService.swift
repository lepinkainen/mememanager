import AppKit
import UniformTypeIdentifiers

class ClipboardService: ObservableObject {
    private let pasteboard = NSPasteboard.general
    
    // MARK: - Reading from Clipboard
    func getImageFromClipboard() -> NSImage? {
        // Try to get image data directly
        if let imageData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: imageData) {
            return image
        }
        
        // Try PNG format
        if let imageData = pasteboard.data(forType: .png),
           let image = NSImage(data: imageData) {
            return image
        }
        
        // Try JPEG format
        if let imageData = pasteboard.data(forType: NSPasteboard.PasteboardType("public.jpeg")),
           let image = NSImage(data: imageData) {
            return image
        }
        
        // Try file URL (for copied files)
        if let fileURL = getFileURLFromClipboard(),
           FileManager.default.fileExists(atPath: fileURL.path) {
            return NSImage(contentsOf: fileURL)
        }
        
        return nil
    }
    
    private func getFileURLFromClipboard() -> URL? {
        // Try to get file URLs directly
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstURL = fileURLs.first {
            return firstURL
        }
        
        // Try to parse string as URL
        guard let string = pasteboard.string(forType: .string),
              let url = URL(string: string),
              url.isFileURL else {
            return nil
        }
        
        return url
    }
    
    func hasImageInClipboard() -> Bool {
        return pasteboard.canReadItem(withDataConformingToTypes: [
            NSPasteboard.PasteboardType.png.rawValue,
            NSPasteboard.PasteboardType.tiff.rawValue,
            "public.jpeg",
            NSPasteboard.PasteboardType.fileURL.rawValue
        ])
    }
    
    // MARK: - Writing to Clipboard
    func copyImageToClipboard(_ image: NSImage) -> Bool {
        guard let tiffData = image.tiffRepresentation else { return false }
        
        pasteboard.clearContents()
        return pasteboard.setData(tiffData, forType: .tiff)
    }
    
    func copyImageFileToClipboard(from url: URL) -> Bool {
        guard let image = NSImage(contentsOf: url) else { return false }
        return copyImageToClipboard(image)
    }
    
    func copyImageDataToClipboard(_ data: Data, type: NSPasteboard.PasteboardType) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setData(data, forType: type)
    }
}