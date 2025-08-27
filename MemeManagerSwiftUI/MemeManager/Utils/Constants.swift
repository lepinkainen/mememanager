import Foundation

struct AppConstants {
    // File System
    static let storageDirectory = "MemeManager"
    static let thumbnailDirectory = "Thumbnails"
    static let databaseName = "MemeManager.db"
    
    // Image Processing
    static let thumbnailSize = CGSize(width: 200, height: 200)
    static let maxImageSize = CGSize(width: 2048, height: 2048)
    
    // Supported Formats
    static let supportedImageTypes = ["png", "jpg", "jpeg", "gif", "webp", "bmp"]
    
    // UI
    static let gridColumns = 4
    static let gridSpacing: CGFloat = 10
    
    // Pagination
    static let pageSize = 50
}