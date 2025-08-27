# Phase 7: Testing & Polish

## Overview

Comprehensive testing, performance optimization, bug fixes, and final polish to ensure the SwiftUI Meme Manager is production-ready and App Store-ready.

## Prerequisites

- [ ] All previous phases completed
- [ ] Core functionality working
- [ ] Advanced features implemented
- [ ] UI/UX feels native to macOS

## Step 1: Comprehensive Testing Strategy

### Unit Testing - Core Components:

```swift
import XCTest
@testable import MemeManager

class DatabaseServiceTests: XCTestCase {
    var databaseService: DatabaseService!
    var testDatabaseURL: URL!

    override func setUp() {
        super.setUp()

        // Create temporary database for testing
        let tempDir = FileManager.default.temporaryDirectory
        testDatabaseURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).db")
        databaseService = DatabaseService(databaseURL: testDatabaseURL)
    }

    override func tearDown() {
        // Clean up test database
        try? FileManager.default.removeItem(at: testDatabaseURL)
        super.tearDown()
    }

    func testImageCRUDOperations() async throws {
        // Test image creation
        let imageId = try await databaseService.addImage(
            filename: "test.png",
            originalName: "Test Image",
            path: "/test/path.png"
        )

        XCTAssertGreaterThan(imageId, 0)

        // Test image retrieval
        let image = try await databaseService.getImage(id: imageId)
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.filename, "test.png")
        XCTAssertEqual(image?.originalName, "Test Image")

        // Test image update
        let success = try await databaseService.updateImage(
            imageId: imageId,
            filename: "updated.png",
            originalName: "Updated Image"
        )
        XCTAssertTrue(success)

        // Test image deletion
        let deleteSuccess = try await databaseService.deleteImage(id: imageId)
        XCTAssertTrue(deleteSuccess)

        // Verify deletion
        let deletedImage = try await databaseService.getImage(id: imageId)
        XCTAssertNil(deletedImage)
    }

    func testTagOperations() async throws {
        // Test tag creation
        let tagId = try await databaseService.addTag(name: "test-tag")
        XCTAssertGreaterThan(tagId, 0)

        // Test duplicate tag handling
        let duplicateTagId = try await databaseService.addTag(name: "test-tag")
        XCTAssertEqual(tagId, duplicateTagId)

        // Test tag retrieval
        let tag = try await databaseService.getTag(name: "test-tag")
        XCTAssertNotNil(tag)
        XCTAssertEqual(tag?.name, "test-tag")
    }

    func testSearchFunctionality() async throws {
        // Create test data
        let imageId1 = try await databaseService.addImage(
            filename: "funny_cat.png",
            originalName: "Funny Cat Meme",
            path: "/test/funny_cat.png"
        )

        let imageId2 = try await databaseService.addImage(
            filename: "dog_meme.jpg",
            originalName: "Dog Picture",
            path: "/test/dog_meme.jpg"
        )

        let tagId = try await databaseService.addTag(name: "animals")
        try await databaseService.addImageTag(imageId: imageId1, tagId: tagId)
        try await databaseService.addImageTag(imageId: imageId2, tagId: tagId)

        // Test search by filename
        let filenameResults = try await databaseService.searchImages(query: "funny")
        XCTAssertEqual(filenameResults.count, 1)
        XCTAssertEqual(filenameResults.first?.id, imageId1)

        // Test search by tag
        let tagResults = try await databaseService.searchImages(query: "animals")
        XCTAssertEqual(tagResults.count, 2)

        // Test search by original name
        let nameResults = try await databaseService.searchImages(query: "dog")
        XCTAssertEqual(nameResults.count, 1)
        XCTAssertEqual(nameResults.first?.id, imageId2)
    }

    func testPerformanceWithLargeDataset() {
        measure {
            // Test performance with 1000 images
            Task {
                for i in 1...1000 {
                    _ = try await databaseService.addImage(
                        filename: "image_\(i).png",
                        originalName: "Image \(i)",
                        path: "/test/image_\(i).png"
                    )
                }

                // Test search performance
                _ = try await databaseService.searchImages(query: "image")
            }
        }
    }
}

class ImageProcessingServiceTests: XCTestCase {
    var imageProcessor: ImageProcessingService!
    var testImageURL: URL!

    override func setUp() {
        super.setUp()

        // Create test image
        let image = NSImage(size: NSSize(width: 500, height: 500))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 500, height: 500).fill()
        image.unlockFocus()

        let tempDir = FileManager.default.temporaryDirectory
        testImageURL = tempDir.appendingPathComponent("test_image.png")

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: testImageURL)
        }

        imageProcessor = ImageProcessingService(fileManager: MockFileManagerService())
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testImageURL)
        super.tearDown()
    }

    func testThumbnailCreation() async {
        let thumbnail = await imageProcessor.createThumbnail(from: testImageURL)

        XCTAssertNotNil(thumbnail)
        XCTAssertLessThanOrEqual(thumbnail?.size.width ?? 0, ImageProcessingService.thumbnailSize.width)
        XCTAssertLessThanOrEqual(thumbnail?.size.height ?? 0, ImageProcessingService.thumbnailSize.height)
    }

    func testImageValidation() {
        XCTAssertTrue(imageProcessor.validateImageFile(at: testImageURL))

        // Test with non-existent file
        let nonExistentURL = URL(fileURLWithPath: "/non/existent/file.png")
        XCTAssertFalse(imageProcessor.validateImageFile(at: nonExistentURL))
    }

    func testImageOptimization() {
        // Create large test image
        let largeImage = NSImage(size: NSSize(width: 3000, height: 3000))

        let optimized = imageProcessor.optimizeImage(largeImage)

        XCTAssertLessThanOrEqual(optimized.size.width, ImageProcessingService.maxImageSize.width)
        XCTAssertLessThanOrEqual(optimized.size.height, ImageProcessingService.maxImageSize.height)
    }
}

class FileManagerServiceTests: XCTestCase {
    var fileManager: FileManagerService!
    var testDirectory: URL!

    override func setUp() {
        super.setUp()

        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent("test_storage_\(UUID().uuidString)")

        fileManager = try! FileManagerService(storageRoot: testDirectory.path)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testDirectory)
        super.tearDown()
    }

    func testUniqueFilenameGeneration() {
        let filename1 = fileManager.generateUniqueFilename(originalName: "test.png", extension: ".png")
        let filename2 = fileManager.generateUniqueFilename(originalName: "test.png", extension: ".png")

        XCTAssertNotEqual(filename1, filename2)
        XCTAssertTrue(filename1.hasSuffix(".png"))
        XCTAssertTrue(filename2.hasSuffix(".png"))
    }

    func testStoragePathGeneration() {
        let filename = "test_image.png"
        let path = fileManager.getStoragePath(for: filename)

        // Should contain year/month structure
        let pathComponents = path.pathComponents
        XCTAssertTrue(pathComponents.contains { $0.count == 4 && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: $0)) })
        XCTAssertTrue(pathComponents.contains { $0.count == 2 && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: $0)) })
    }
}
```

### Integration Testing:

```swift
class IntegrationTests: XCTestCase {
    var serviceManager: ServiceManager!
    var testDirectory: URL!

    override func setUp() {
        super.setUp()

        // Set up test environment
        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent("integration_test_\(UUID().uuidString)")

        serviceManager = try! ServiceManager(testDirectory: testDirectory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testDirectory)
        super.tearDown()
    }

    func testCompleteImageImportWorkflow() async throws {
        // Create test image
        let testImage = createTestImage()
        let testImageURL = testDirectory.appendingPathComponent("test_import.png")
        saveImage(testImage, to: testImageURL)

        // Import image
        let (filename, path) = try await serviceManager.fileManager.saveImageFromURL(
            testImageURL,
            originalName: "Test Import"
        )

        // Add to database
        let imageId = try await serviceManager.database.addImage(
            filename: filename,
            originalName: "Test Import",
            path: path
        )

        // Add tags
        let tagId = try await serviceManager.database.addTag(name: "test")
        try await serviceManager.database.addImageTag(imageId: imageId, tagId: tagId)

        // Search for image
        let searchResults = try await serviceManager.database.searchImages(query: "test")
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults.first?.id, imageId)

        // Verify thumbnail creation
        let thumbnail = await serviceManager.thumbnailManager.getThumbnail(for: searchResults.first!)
        XCTAssertNotNil(thumbnail)
    }

    func testSearchAndTagWorkflow() async throws {
        // Create multiple test images with tags
        let images = try await createTestImageCollection()

        // Test tag-based search
        let animalResults = try await serviceManager.database.searchImages(query: "animals")
        XCTAssertGreaterThan(animalResults.count, 0)

        // Test filename search
        let catResults = try await serviceManager.database.searchImages(query: "cat")
        XCTAssertGreaterThan(catResults.count, 0)

        // Test combined search
        let funnyResults = try await serviceManager.database.searchImages(query: "funny")
        XCTAssertGreaterThan(funnyResults.count, 0)
    }

    private func createTestImageCollection() async throws -> [MemeImage] {
        let testData = [
            ("funny_cat.png", "Funny Cat", ["funny", "animals", "cats"]),
            ("serious_dog.jpg", "Serious Dog", ["serious", "animals", "dogs"]),
            ("random_meme.png", "Random Meme", ["random", "funny"])
        ]

        var images: [MemeImage] = []

        for (filename, originalName, tags) in testData {
            let testImage = createTestImage()
            let testImageURL = testDirectory.appendingPathComponent(filename)
            saveImage(testImage, to: testImageURL)

            let (savedFilename, path) = try await serviceManager.fileManager.saveImageFromURL(
                testImageURL,
                originalName: originalName
            )

            let imageId = try await serviceManager.database.addImage(
                filename: savedFilename,
                originalName: originalName,
                path: path
            )

            for tagName in tags {
                let tagId = try await serviceManager.database.addTag(name: tagName)
                try await serviceManager.database.addImageTag(imageId: imageId, tagId: tagId)
            }

            if let image = try await serviceManager.database.getImage(id: imageId) {
                images.append(image)
            }
        }

        return images
    }
}
```

### Step 1 Checklist:

- [ ] Create comprehensive unit tests for all services
- [ ] Implement integration tests for complete workflows
- [ ] Add performance tests for large datasets
- [ ] Test error handling and edge cases
- [ ] Verify thread safety and concurrent operations
- [ ] Test with various image formats and sizes

## Step 2: UI Testing & Accessibility

### UI Testing Suite:

```swift
import XCTest

class UITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testMainWindowLaunch() {
        // Test that main window appears
        XCTAssertTrue(app.windows["main"].exists)

        // Test sidebar elements
        XCTAssertTrue(app.staticTexts["🎭 Meme Manager"].exists)
        XCTAssertTrue(app.buttons["📁 Select Files"].exists)
        XCTAssertTrue(app.buttons["📋 Paste from Clipboard"].exists)

        // Test search field
        XCTAssertTrue(app.searchFields["Search memes..."].exists)
    }

    func testFileImportWorkflow() {
        // Click import button
        app.buttons["📁 Select Files"].click()

        // File dialog should appear
        // Note: Testing file dialogs requires special handling

        // Test that import feedback appears
        let statusLabel = app.staticTexts.matching(identifier: "statusLabel").element
        XCTAssertTrue(statusLabel.exists)
    }

    func testSearchFunctionality() {
        let searchField = app.searchFields["Search memes..."]
        searchField.click()
        searchField.typeText("test")

        // Should show search results or "no results" message
        // This test requires pre-populated test data
    }

    func testKeyboardShortcuts() {
        // Test Cmd+O for import
        app.typeKey("o", modifierFlags: .command)
        // Should trigger file import

        // Test Cmd+F for search
        app.typeKey("f", modifierFlags: .command)
        // Should focus search field

        // Test Cmd+V for paste
        app.typeKey("v", modifierFlags: .command)
        // Should trigger clipboard import
    }

    func testContextMenus() {
        // Right-click on image thumbnail (requires test data)
        // Verify context menu appears with expected options
    }

    func testPreferencesWindow() {
        // Open preferences
        app.typeKey(",", modifierFlags: .command)

        // Verify preferences window appears
        XCTAssertTrue(app.windows["preferences"].exists)

        // Test tab switching
        app.buttons["Import"].click()
        app.buttons["Storage"].click()
        app.buttons["Advanced"].click()
    }
}

// Accessibility Testing
class AccessibilityTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }

    func testVoiceOverCompatibility() {
        // Enable VoiceOver for testing
        app.accessibilityActivate()

        // Test that all UI elements have proper accessibility labels
        let importButton = app.buttons["📁 Select Files"]
        XCTAssertNotNil(importButton.label)
        XCTAssertTrue(importButton.isEnabled)

        let searchField = app.searchFields["Search memes..."]
        XCTAssertNotNil(searchField.placeholderValue)
    }

    func testKeyboardNavigation() {
        // Test that all interactive elements are reachable via keyboard
        app.typeKey("\t", modifierFlags: [])

        // Should navigate through focusable elements
        // Test requires systematic navigation through all UI elements
    }

    func testHighContrastMode() {
        // Test UI visibility in high contrast mode
        // This requires system-level configuration changes
    }

    func testTextSizeScaling() {
        // Test UI with different text size settings
        // Verify that UI scales appropriately
    }
}
```

### Step 2 Checklist:

- [ ] Create UI tests for all major workflows
- [ ] Test keyboard navigation and shortcuts
- [ ] Verify VoiceOver compatibility
- [ ] Test with different accessibility settings
- [ ] Validate color contrast and text scaling
- [ ] Test with system appearance changes (light/dark mode)

## Step 3: Performance Optimization

### Performance Testing & Optimization:

```swift
class PerformanceTests: XCTestCase {

    func testThumbnailLoadingPerformance() {
        // Test thumbnail loading with 100+ images
        measure {
            // Load thumbnails for large image collection
        }
    }

    func testSearchPerformance() {
        // Test search performance with large dataset
        measure {
            // Perform complex search queries
        }
    }

    func testMemoryUsage() {
        // Monitor memory usage during image loading
        let startMemory = getMemoryUsage()

        // Load many images
        loadLargeImageCollection()

        let endMemory = getMemoryUsage()
        let memoryIncrease = endMemory - startMemory

        // Assert memory usage is within acceptable limits
        XCTAssertLessThan(memoryIncrease, 100_000_000) // 100MB limit
    }

    func testDatabasePerformance() {
        measure {
            // Test database operations with large dataset
        }
    }

    private func getMemoryUsage() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4

        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return 0 }
        return info.phys_footprint
    }
}

// Performance optimizations to implement:
class PerformanceOptimizations {

    // Implement lazy loading for image grid
    func optimizeImageGridLoading() {
        // Only load thumbnails for visible cells
        // Preload thumbnails for cells about to become visible
        // Dispose of thumbnails for cells that are far off-screen
    }

    // Implement database query optimization
    func optimizeDatabaseQueries() {
        // Use prepared statements for repeated queries
        // Implement query result caching
        // Use database indexes for frequently searched columns
    }

    // Implement image processing optimization
    func optimizeImageProcessing() {
        // Use background queues for image processing
        // Implement image processing pipeline with proper threading
        // Cache processed images to avoid reprocessing
    }

    // Implement memory management
    func optimizeMemoryUsage() {
        // Implement proper image disposal
        // Use autoreleasepool for batch operations
        // Monitor and limit cache sizes
    }
}
```

### Step 3 Checklist:

- [ ] Run performance tests with large datasets (1000+ images)
- [ ] Optimize thumbnail loading and caching
- [ ] Improve database query performance
- [ ] Optimize memory usage and prevent leaks
- [ ] Test with various system configurations
- [ ] Profile with Instruments to identify bottlenecks

## Step 4: Bug Fixes & Edge Cases

### Common Issues to Test and Fix:

```swift
class EdgeCaseTests: XCTestCase {

    func testCorruptedImageHandling() {
        // Test with corrupted image files
        // Ensure app doesn't crash and provides user feedback
    }

    func testLargeImageHandling() {
        // Test with extremely large images (100MB+)
        // Verify memory usage and processing time
    }

    func testSpecialCharactersInFilenames() {
        // Test with filenames containing unicode, spaces, special characters
        let problematicNames = [
            "file with spaces.png",
            "файл_на_русском.jpg",
            "🎭🎨🎪.gif",
            "file-with-émojis-and-accénts.png"
        ]

        for name in problematicNames {
            // Test import and storage
        }
    }

    func testDatabaseConnectionLoss() {
        // Test behavior when database becomes unavailable
        // Ensure graceful degradation and recovery
    }

    func testDiskSpaceExhaustion() {
        // Test behavior when disk space runs out
        // Ensure proper error handling and user notification
    }

    func testConcurrentOperations() {
        // Test simultaneous import, search, and tag operations
        // Verify data consistency and no race conditions
    }

    func testEmptyStates() {
        // Test app behavior with no images
        // Test search with no results
        // Test tag management with no tags
    }

    func testNetworkImageImport() {
        // Test importing images from URLs
        // Handle network errors and timeouts
    }

    func testFileSystemPermissions() {
        // Test behavior with limited file system permissions
        // Ensure proper error messages and fallback behavior
    }
}

// Bug Fix Implementation:
class BugFixes {

    func fixThumbnailCachingIssues() {
        // Fix: Thumbnails not updating when original image changes
        // Solution: Check file modification dates

        // Fix: Memory leaks in thumbnail cache
        // Solution: Implement proper cache eviction
    }

    func fixSearchResultsInconsistency() {
        // Fix: Search results not updating immediately after tag changes
        // Solution: Implement proper data flow and refresh mechanisms
    }

    func fixUIResponseiveness() {
        // Fix: UI freezing during large operations
        // Solution: Move heavy operations to background queues
    }

    func fixDataCorruption() {
        // Fix: Database corruption during concurrent writes
        // Solution: Implement proper transaction management
    }
}
```

### Step 4 Checklist:

- [ ] Test all edge cases and error conditions
- [ ] Fix memory leaks and performance issues
- [ ] Handle file system and permission errors gracefully
- [ ] Test with corrupted or unusual image files
- [ ] Verify concurrent operation safety
- [ ] Test empty states and error recovery

## Step 5: App Store Preparation

### App Store Compliance:

```swift
// App Store requirements checklist

class AppStoreCompliance {

    func implementPrivacyCompliance() {
        // Ensure no data collection without user consent
        // Add privacy policy if needed
        // Implement proper data handling practices
    }

    func addCodesigning() {
        // Set up proper code signing for distribution
        // Configure entitlements for sandbox mode
        // Test with notarization requirements
    }

    func createAppStoreMetadata() {
        // Create app description and keywords
        // Prepare screenshots for App Store
        // Write release notes
    }

    func testSandboxCompliance() {
        // Ensure app works properly in sandbox mode
        // Test file access permissions
        // Verify no unauthorized system access
    }

    func addHelpDocumentation() {
        // Create in-app help system
        // Add user guide and tutorials
        // Implement support contact information
    }
}

// App Store Assets:
struct AppStoreAssets {
    // App icon in all required sizes
    // Screenshots for different screen sizes
    // App preview video (optional)
    // Marketing materials
    // Localized content (if supporting multiple languages)
}
```

### Localization Preparation:

```swift
// Prepare for localization
class LocalizationSupport {

    func extractLocalizedStrings() {
        // Use NSLocalizedString for all user-facing text
        // Create Localizable.strings files
        // Test with pseudo-localization
    }

    func testRightToLeftLayouts() {
        // Test UI with RTL languages
        // Ensure proper text alignment and layout
    }

    func addCultureSpecificFeatures() {
        // Handle date/time formatting
        // Number formatting
        // Currency handling (if applicable)
    }
}
```

### Step 5 Checklist:

- [ ] Ensure app meets App Store guidelines
- [ ] Set up proper code signing and notarization
- [ ] Test in sandbox mode
- [ ] Create App Store metadata and screenshots
- [ ] Prepare for localization if desired
- [ ] Add help documentation and user guides

## Step 6: Final Polish & User Experience

### UX Improvements:

- [ ] Add loading animations and progress indicators
- [ ] Implement smooth transitions between views
- [ ] Add haptic feedback where appropriate
- [ ] Polish empty states with helpful illustrations
- [ ] Add onboarding flow for new users
- [ ] Implement tooltips and contextual help
- [ ] Add confirmation dialogs for destructive actions
- [ ] Improve error messages with actionable suggestions

### Visual Polish:

- [ ] Consistent spacing and alignment throughout app
- [ ] Proper color scheme and contrast ratios
- [ ] Smooth animations and transitions
- [ ] Professional app icon and visual assets
- [ ] Consistent typography and font usage
- [ ] Polish dark mode appearance
- [ ] Add visual feedback for all interactions

### Performance Final Check:

- [ ] App launches quickly (< 3 seconds)
- [ ] Smooth scrolling with large image collections
- [ ] Responsive search with < 500ms delay
- [ ] Efficient memory usage (< 200MB typical)
- [ ] No memory leaks during extended use
- [ ] Stable performance with 1000+ images

## Validation Checklist

- [ ] ✅ All unit tests pass
- [ ] ✅ Integration tests verify complete workflows
- [ ] ✅ UI tests cover all major user interactions
- [ ] ✅ Performance is acceptable under load
- [ ] ✅ No memory leaks or crashes
- [ ] ✅ Accessibility requirements met
- [ ] ✅ App Store compliance verified
- [ ] ✅ User experience is polished and intuitive

## Release Preparation

- [ ] Create release build configuration
- [ ] Test final build thoroughly
- [ ] Prepare release notes
- [ ] Create backup and rollback plan
- [ ] Set up crash reporting and analytics
- [ ] Prepare user documentation
- [ ] Plan marketing and launch strategy

## Success Metrics

- [ ] App launches without errors
- [ ] All Python app features successfully replicated
- [ ] Performance exceeds Python version
- [ ] User experience feels native to macOS
- [ ] Ready for App Store submission (if desired)
- [ ] Comprehensive test coverage (> 80%)
- [ ] No critical bugs or crashes

---

**Estimated Time**: 1-2 weeks for comprehensive testing and polish, depending on issues found

**Total Project Timeline**: 3-5 weeks for complete SwiftUI implementation
