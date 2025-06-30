# Phase 2: Core Architecture & Data Layer

## Overview

Implement the core data models, database layer, and fundamental services that mirror the Python implementation's functionality.

## Prerequisites

- [x] Phase 1 (Project Setup) completed
- [x] SQLite.swift package integrated
- [x] Understanding of existing Python database schema

## Step 1: Database Schema Design

Based on the Python implementation, we need these tables:

- `images`: id, filename, original_name, path, created_date, updated_date
- `tags`: id, name
- `image_tags`: image_id, tag_id (junction table)

### DatabaseService.swift Implementation:

```swift
import Foundation
import SQLite

class DatabaseService: ObservableObject {
    private var db: Connection?
    private let imagesTable = Table("images")
    private let tagsTable = Table("tags")
    private let imageTagsTable = Table("image_tags")

    // Images table columns
    private let imageId = Expression<Int64>("id")
    private let imageFilename = Expression<String>("filename")
    private let imageOriginalName = Expression<String>("original_name")
    private let imagePath = Expression<String>("path")
    private let imageCreatedDate = Expression<String>("created_date")
    private let imageUpdatedDate = Expression<String>("updated_date")

    // Tags table columns
    private let tagId = Expression<Int64>("id")
    private let tagName = Expression<String>("name")

    // Junction table columns
    private let junctionImageId = Expression<Int64>("image_id")
    private let junctionTagId = Expression<Int64>("tag_id")

    init() {
        createDatabase()
    }

    private func createDatabase() {
        // Implementation details...
    }
}
```

### Step 1 Checklist:

- [x] Create `DatabaseService.swift` with SQLite.swift integration
- [x] Define table structures matching Python schema
- [x] Implement database initialization
- [x] Create database connection management
- [x] Add error handling for database operations
- [x] Test database creation and connection

## Step 2: Data Models

### MemeImage.swift:

```swift
import Foundation

struct MemeImage: Identifiable, Codable {
    let id: Int64
    let filename: String
    let originalName: String
    let path: String
    let createdDate: Date
    let updatedDate: Date
    var tags: [Tag] = []

    // Computed properties
    var url: URL? {
        URL(fileURLWithPath: path)
    }

    var displayName: String {
        originalName.isEmpty ? filename : originalName
    }
}

extension MemeImage {
    static let sample = MemeImage(
        id: 1,
        filename: "sample.png",
        originalName: "Sample Meme",
        path: "/path/to/sample.png",
        createdDate: Date(),
        updatedDate: Date()
    )
}
```

### Tag.swift:

```swift
import Foundation

struct Tag: Identifiable, Codable, Hashable {
    let id: Int64
    let name: String

    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Tag {
    static let sample = Tag(id: 1, name: "funny")
}
```

### Step 2 Checklist:

- [x] Create `MemeImage` model with all required properties
- [x] Create `Tag` model with proper conformances
- [x] Add sample data for previews and testing
- [x] Implement proper date handling (String ↔ Date conversion)
- [x] Add computed properties for UI convenience
- [x] Test model serialization/deserialization

## Step 3: Database Operations Implementation

### Core CRUD Operations:

```swift
extension DatabaseService {
    // Image operations
    func addImage(_ image: MemeImage) throws -> Int64 { }
    func updateImage(_ image: MemeImage) throws { }
    func deleteImage(id: Int64) throws { }
    func getImage(id: Int64) throws -> MemeImage? { }
    func getAllImages() throws -> [MemeImage] { }

    // Tag operations
    func addTag(name: String) throws -> Int64 { }
    func getTag(name: String) throws -> Tag? { }
    func getAllTags() throws -> [Tag] { }

    // Association operations
    func addImageTag(imageId: Int64, tagId: Int64) throws { }
    func removeImageTag(imageId: Int64, tagId: Int64) throws { }
    func getImageTags(imageId: Int64) throws -> [Tag] { }

    // Search operations
    func searchImages(query: String) throws -> [MemeImage] { }
    func getImagesByTag(tagName: String) throws -> [MemeImage] { }
}
```

### Step 3 Checklist:

- [x] Implement all image CRUD operations
- [x] Implement tag management operations
- [x] Implement image-tag association operations
- [x] Implement search functionality (name + tags)
- [x] Add proper error handling and validation
- [x] Test all database operations thoroughly
- [ ] Add database migration support if needed

## Step 4: File Management Service

### FileManagerService.swift:

```swift
import Foundation
import UniformTypeIdentifiers

class FileManagerService: ObservableObject {
    private let fileManager = FileManager.default
    private let storageDirectory: URL
    private let thumbnailDirectory: URL

    init() throws {
        // Set up storage directories in user's Documents
        let documentsPath = fileManager.urls(for: .documentDirectory,
                                           in: .userDomainMask).first!

        storageDirectory = documentsPath.appendingPathComponent("MemeManager/Images")
        thumbnailDirectory = documentsPath.appendingPathComponent("MemeManager/Thumbnails")

        try createDirectoriesIfNeeded()
    }

    // File operations
    func saveImage(from sourceURL: URL, originalName: String) throws -> (filename: String, path: String)
    func generateUniqueFilename(originalName: String, extension: String) -> String
    func getStoragePath(for filename: String) -> URL
    func deleteImageFile(at path: String) throws
    func validateImageFile(at url: URL) -> Bool

    // Directory management
    private func createDirectoriesIfNeeded() throws
    func getStorageUsage() -> StorageInfo
}

struct StorageInfo {
    let totalSizeBytes: Int64
    let totalSizeMB: Double
    let fileCount: Int
}
```

### Step 4 Checklist:

- [x] Create `FileManagerService` with proper directory management
- [x] Implement unique filename generation (matching Python logic)
- [x] Add YYYY/MM directory organization
- [x] Implement file validation for supported image types
- [x] Add storage usage calculation
- [x] Handle file system errors gracefully
- [x] Test file operations with various image types

## Step 5: Image Processing Service

### ImageProcessingService.swift:

```swift
import AppKit
import UniformTypeIdentifiers

class ImageProcessingService: ObservableObject {
    static let thumbnailSize = CGSize(width: 200, height: 200)
    static let maxImageSize = CGSize(width: 2048, height: 2048)

    // Image processing
    func createThumbnail(from imageURL: URL) -> NSImage?
    func optimizeImage(_ image: NSImage) -> NSImage?
    func getImageInfo(from url: URL) -> ImageInfo?

    // Clipboard operations
    func saveImageFromClipboard(originalName: String) throws -> (filename: String, path: String)?
    func copyImageToClipboard(from url: URL) throws

    // Validation
    func isSupportedImageType(_ url: URL) -> Bool
}

struct ImageInfo {
    let size: CGSize
    let fileSize: Int64
    let type: UTType
}
```

### Step 5 Checklist:

- [x] Create `ImageProcessingService` with NSImage handling
- [x] Implement thumbnail generation matching Python logic
- [x] Add image optimization (resize if too large)
- [x] Implement clipboard image handling (save from/copy to)
- [x] Add image format validation
- [x] Test with various image formats and sizes
- [x] Handle memory management for large images

## Step 6: Service Integration & Testing

### Create a centralized service manager:

```swift
class ServiceManager: ObservableObject {
    let database: DatabaseService
    let fileManager: FileManagerService
    let imageProcessor: ImageProcessingService

    init() throws {
        self.database = DatabaseService()
        self.fileManager = try FileManagerService()
        self.imageProcessor = ImageProcessingService()
    }
}
```

### Step 6 Checklist:

- [x] Create `ServiceManager` to coordinate all services
- [x] Add service manager to app's environment
- [x] Test service integration and data flow
- [ ] Create unit tests for core functionality
- [x] Test error handling across services
- [x] Validate against Python implementation behavior

## Step 7: Architecture Validation

### Create test data and operations:

- [x] Create sample database with test images and tags
- [x] Test image import workflow end-to-end
- [x] Verify search functionality works correctly
- [x] Test tag management operations
- [x] Validate file organization matches Python version
- [x] Check performance with moderate dataset (100+ images)

### Integration Tests:

```swift
// Example test structure
class CoreArchitectureTests: XCTestCase {
    var serviceManager: ServiceManager!

    override func setUp() {
        // Setup test environment
    }

    func testImageImportWorkflow() {
        // Test complete import process
    }

    func testSearchFunctionality() {
        // Test search across names and tags
    }

    func testTagManagement() {
        // Test tag CRUD operations
    }
}
```

### Step 7 Checklist:

- [ ] Write comprehensive unit tests
- [x] Test error conditions and edge cases
- [x] Validate data consistency
- [ ] Test concurrent operations if applicable
- [x] Performance test with larger datasets
- [x] Compare output with Python implementation

## Validation Checklist

- [x] ✅ Database service creates and manages SQLite database
- [x] ✅ All CRUD operations work correctly
- [x] ✅ File management service handles image storage
- [x] ✅ Image processing service handles thumbnails and optimization
- [x] ✅ Search functionality matches Python implementation
- [x] ✅ Services integrate properly with error handling
- [ ] ✅ Unit tests pass for all core functionality

## Common Issues & Solutions

- **SQLite connection issues**: Check file permissions and sandbox entitlements
- **Image loading problems**: Verify UTType handling and format support
- **File system errors**: Ensure proper sandboxing configuration
- **Memory issues**: Implement proper image loading and disposal
- **Performance problems**: Consider lazy loading and caching strategies

## Next Steps

Once this phase is complete, proceed to **03-UI-Foundation.md** for building the user interface.

---

**Estimated Time**: 1-2 days for core implementation, additional time for thorough testing
