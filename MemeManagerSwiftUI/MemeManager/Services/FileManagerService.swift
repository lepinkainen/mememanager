import Foundation

class FileManagerService {
    static let shared = FileManagerService()
    
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private init() {
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        let storageURL = documentsDirectory.appendingPathComponent(AppConstants.storageDirectory)
        let memesURL = storageURL.appendingPathComponent("memes")
        let thumbnailsURL = storageURL.appendingPathComponent("thumbnails")
        
        [storageURL, memesURL, thumbnailsURL].forEach { url in
            if !fileManager.fileExists(atPath: url.path) {
                try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            }
        }
    }
    
    func getStorageURL(for year: Int, month: Int) -> URL {
        let yearMonth = String(format: "%04d/%02d", year, month)
        return documentsDirectory
            .appendingPathComponent(AppConstants.storageDirectory)
            .appendingPathComponent("memes")
            .appendingPathComponent(yearMonth)
    }
    
    func getThumbnailURL(for year: Int, month: Int) -> URL {
        let yearMonth = String(format: "%04d/%02d", year, month)
        return documentsDirectory
            .appendingPathComponent(AppConstants.storageDirectory)
            .appendingPathComponent("thumbnails")
            .appendingPathComponent(yearMonth)
    }
    
    func generateUniqueFilename(originalName: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let randomSuffix = String(format: "%08x", arc4random())
        let nameWithoutExtension = (originalName as NSString).deletingPathExtension
        let fileExtension = (originalName as NSString).pathExtension
        
        return "\(timestamp)_\(randomSuffix)_\(nameWithoutExtension).\(fileExtension)"
    }
    
    func saveImage(from sourceURL: URL, originalName: String) -> String? {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        let storageURL = getStorageURL(for: year, month: month)
        
        // Create directory if needed
        if !fileManager.fileExists(atPath: storageURL.path) {
            try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)
        }
        
        let filename = generateUniqueFilename(originalName: originalName)
        let destinationURL = storageURL.appendingPathComponent(filename)
        
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func getThumbnailPath(for image: MemeImage) -> URL {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: image.createdDate)
        let month = calendar.component(.month, from: image.createdDate)
        
        let thumbnailDirectory = getThumbnailURL(for: year, month: month)
        let thumbnailFilename = (image.filename as NSString).deletingPathExtension + "_thumb.jpg"
        
        return thumbnailDirectory.appendingPathComponent(thumbnailFilename)
    }
    
    // Legacy method for backward compatibility
    func getThumbnailPath(for filename: String) -> URL {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        let thumbnailDirectory = getThumbnailURL(for: year, month: month)
        let thumbnailFilename = (filename as NSString).deletingPathExtension + "_thumb.jpg"
        
        return thumbnailDirectory.appendingPathComponent(thumbnailFilename)
    }
    
    func saveImageFromData(_ data: Data, originalName: String) -> String? {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        let storageURL = getStorageURL(for: year, month: month)
        
        // Create directory if needed
        if !fileManager.fileExists(atPath: storageURL.path) {
            try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)
        }
        
        let filename = generateUniqueFilename(originalName: originalName)
        let destinationURL = storageURL.appendingPathComponent(filename)
        
        do {
            try data.write(to: destinationURL)
            return destinationURL.path
        } catch {
            print("Error saving image from data: \(error)")
            return nil
        }
    }
}