import Foundation
import SQLite
import SwiftUI

class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    
    private var db: Connection?
    
    // Table definitions
    private let images = Table("images")
    private let tags = Table("tags")
    private let imageTags = Table("image_tags")
    
    // Images table columns
    private let imageId = Expression<Int>("id")
    private let imageFilename = Expression<String>("filename")
    private let imageOriginalName = Expression<String>("original_name")
    private let imagePath = Expression<String>("path")
    private let imageCreatedDate = Expression<Date>("created_date")
    private let imageUpdatedDate = Expression<Date>("updated_date")
    
    // Tags table columns
    private let tagId = Expression<Int>("id")
    private let tagName = Expression<String>("name")
    
    // Image-Tags junction table columns
    private let jtImageId = Expression<Int>("image_id")
    private let jtTagId = Expression<Int>("tag_id")
    
    private init() {
        initializeDatabase()
    }
    
    private func initializeDatabase() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let storageURL = documentsPath.appendingPathComponent(AppConstants.storageDirectory)
            
            // Create storage directory if needed
            if !FileManager.default.fileExists(atPath: storageURL.path) {
                try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)
            }
            
            let dbURL = storageURL.appendingPathComponent("memes.db")
            db = try Connection(dbURL.path)
            
            createTables()
        } catch {
            print("Database initialization failed: \(error)")
        }
    }
    
    private func createTables() {
        do {
            // Create images table
            try db?.run(images.create(ifNotExists: true) { t in
                t.column(imageId, primaryKey: .autoincrement)
                t.column(imageFilename)
                t.column(imageOriginalName)
                t.column(imagePath)
                t.column(imageCreatedDate)
                t.column(imageUpdatedDate)
            })
            
            // Create tags table
            try db?.run(tags.create(ifNotExists: true) { t in
                t.column(tagId, primaryKey: .autoincrement)
                t.column(tagName, unique: true)
            })
            
            // Create image-tags junction table
            try db?.run(imageTags.create(ifNotExists: true) { t in
                t.column(jtImageId)
                t.column(jtTagId)
                t.primaryKey(jtImageId, jtTagId)
                t.foreignKey(jtImageId, references: images, imageId, delete: .cascade)
                t.foreignKey(jtTagId, references: tags, tagId, delete: .cascade)
            })
            
            print("Database tables created successfully")
        } catch {
            print("Failed to create tables: \(error)")
        }
    }
    
    // MARK: - Image Operations
    func createImage(_ image: MemeImage) -> Bool {
        guard let db = db else { return false }
        
        do {
            let insert = images.insert(
                imageFilename <- image.filename,
                imageOriginalName <- image.originalName,
                imagePath <- image.path,
                imageCreatedDate <- image.createdDate,
                imageUpdatedDate <- image.updatedDate
            )
            try db.run(insert)
            return true
        } catch {
            print("Failed to insert image: \(error)")
            return false
        }
    }
    
    func getAllImages() -> [MemeImage] {
        guard let db = db else { return [] }
        
        do {
            var memeImages: [MemeImage] = []
            for row in try db.prepare(images.order(imageCreatedDate.desc)) {
                let image = MemeImage(
                    databaseId: row[imageId],
                    filename: row[imageFilename],
                    originalName: row[imageOriginalName],
                    path: row[imagePath],
                    createdDate: row[imageCreatedDate],
                    updatedDate: row[imageUpdatedDate],
                    tags: getTagsForImage(imageId: row[imageId])
                )
                memeImages.append(image)
            }
            return memeImages
        } catch {
            print("Failed to fetch images: \(error)")
            return []
        }
    }
    
    func getImage(by id: Int) -> MemeImage? {
        guard let db = db else { return nil }
        
        do {
            let query = images.filter(imageId == id)
            if let row = try db.pluck(query) {
                return MemeImage(
                    databaseId: row[imageId],
                    filename: row[imageFilename],
                    originalName: row[imageOriginalName],
                    path: row[imagePath],
                    createdDate: row[imageCreatedDate],
                    updatedDate: row[imageUpdatedDate],
                    tags: getTagsForImage(imageId: row[imageId])
                )
            }
        } catch {
            print("Failed to fetch image: \(error)")
        }
        return nil
    }
    
    func updateImage(_ image: MemeImage) -> Bool {
        guard let db = db, let id = image.databaseId else { return false }
        
        do {
            let imageToUpdate = images.filter(imageId == id)
            let update = imageToUpdate.update(
                imageFilename <- image.filename,
                imageOriginalName <- image.originalName,
                imagePath <- image.path,
                imageUpdatedDate <- Date()
            )
            try db.run(update)
            return true
        } catch {
            print("Failed to update image: \(error)")
            return false
        }
    }
    
    func deleteImage(id: Int) -> Bool {
        guard let db = db else { return false }
        
        do {
            let imageToDelete = images.filter(imageId == id)
            try db.run(imageToDelete.delete())
            return true
        } catch {
            print("Failed to delete image: \(error)")
            return false
        }
    }
    
    // MARK: - Tag Operations
    func createTag(_ tag: Tag) -> Bool {
        guard let db = db else { return false }
        
        do {
            let insert = tags.insert(tagName <- tag.name)
            try db.run(insert)
            return true
        } catch {
            print("Failed to insert tag: \(error)")
            return false
        }
    }
    
    func createTagIfNotExists(name: String) -> Int? {
        guard let db = db else { return nil }
        
        // First check if tag exists
        if let existingTag = getTagByName(name) {
            return existingTag.id
        }
        
        // Create new tag
        do {
            let insert = tags.insert(tagName <- name)
            let tagId = try db.run(insert)
            return Int(tagId)
        } catch {
            print("Failed to create tag: \(error)")
            return nil
        }
    }
    
    func getAllTags() -> [Tag] {
        guard let db = db else { return [] }
        
        do {
            var tagList: [Tag] = []
            for row in try db.prepare(tags.order(tagName)) {
                let tag = Tag(
                    id: row[tagId],
                    name: row[tagName]
                )
                tagList.append(tag)
            }
            return tagList
        } catch {
            print("Failed to fetch tags: \(error)")
            return []
        }
    }
    
    func getTagByName(_ name: String) -> Tag? {
        guard let db = db else { return nil }
        
        do {
            let query = tags.filter(tagName == name)
            if let row = try db.pluck(query) {
                return Tag(id: row[tagId], name: row[tagName])
            }
        } catch {
            print("Failed to fetch tag by name: \(error)")
        }
        return nil
    }
    
    func getTagsForImage(imageId: Int) -> [Tag] {
        guard let db = db else { return [] }
        
        do {
            var imageTagsList: [Tag] = []
            let query = tags
                .join(imageTags, on: tagId == jtTagId)
                .filter(jtImageId == imageId)
                .order(tagName)
            
            for row in try db.prepare(query) {
                let tag = Tag(
                    id: row[tagId],
                    name: row[tagName]
                )
                imageTagsList.append(tag)
            }
            return imageTagsList
        } catch {
            print("Failed to fetch tags for image: \(error)")
            return []
        }
    }
    
    func deleteTag(id: Int) -> Bool {
        guard let db = db else { return false }
        
        do {
            let tagToDelete = tags.filter(tagId == id)
            try db.run(tagToDelete.delete())
            return true
        } catch {
            print("Failed to delete tag: \(error)")
            return false
        }
    }
    
    // MARK: - Image-Tag Association Operations
    func addTagToImage(imageId: Int, tagId: Int) -> Bool {
        guard let db = db else { return false }
        
        do {
            let insert = imageTags.insert(
                jtImageId <- imageId,
                jtTagId <- tagId
            )
            try db.run(insert)
            return true
        } catch {
            print("Failed to associate tag with image: \(error)")
            return false
        }
    }
    
    func addTagsToImage(imageId: Int, tagNames: [String]) -> Bool {
        var success = true
        
        for tagName in tagNames {
            guard let tagId = createTagIfNotExists(name: tagName) else {
                success = false
                continue
            }
            
            if !addTagToImage(imageId: imageId, tagId: tagId) {
                success = false
            }
        }
        
        return success
    }
    
    func removeTagFromImage(imageId: Int, tagId: Int) -> Bool {
        guard let db = db else { return false }
        
        do {
            let association = imageTags.filter(jtImageId == imageId && jtTagId == tagId)
            try db.run(association.delete())
            return true
        } catch {
            print("Failed to remove tag from image: \(error)")
            return false
        }
    }
    
    func removeAllTagsFromImage(imageId: Int) -> Bool {
        guard let db = db else { return false }
        
        do {
            let associations = imageTags.filter(jtImageId == imageId)
            try db.run(associations.delete())
            return true
        } catch {
            print("Failed to remove all tags from image: \(error)")
            return false
        }
    }
    
    // MARK: - Search Operations
    func searchImages(query: String) -> [MemeImage] {
        guard let db = db else { return [] }
        
        if query.isEmpty {
            return getAllImages()
        }
        
        do {
            var memeImages: [MemeImage] = []
            let searchQuery = images.filter(
                imageOriginalName.like("%\(query)%") ||
                imageFilename.like("%\(query)%")
            ).order(imageCreatedDate.desc)
            
            for row in try db.prepare(searchQuery) {
                let image = MemeImage(
                    databaseId: row[imageId],
                    filename: row[imageFilename],
                    originalName: row[imageOriginalName],
                    path: row[imagePath],
                    createdDate: row[imageCreatedDate],
                    updatedDate: row[imageUpdatedDate],
                    tags: getTagsForImage(imageId: row[imageId])
                )
                memeImages.append(image)
            }
            return memeImages
        } catch {
            print("Failed to search images: \(error)")
            return []
        }
    }
    
    func searchImagesByTags(tagNames: [String]) -> [MemeImage] {
        guard !tagNames.isEmpty else { return [] }
        
        // Simple approach: get all images and filter by tags in memory
        let allImages = getAllImages()
        return allImages.filter { image in
            let imageTags = image.tags.map { $0.name.lowercased() }
            return tagNames.allSatisfy { tagName in
                imageTags.contains(where: { $0.contains(tagName.lowercased()) })
            }
        }
    }
    
    func searchImagesWithTextAndTags(textQuery: String, tagNames: [String]) -> [MemeImage] {
        if textQuery.isEmpty && tagNames.isEmpty {
            return getAllImages()
        }
        
        if tagNames.isEmpty {
            return searchImages(query: textQuery)
        }
        
        if textQuery.isEmpty {
            return searchImagesByTags(tagNames: tagNames)
        }
        
        // Combine text and tag search
        let textResults = searchImages(query: textQuery)
        return textResults.filter { image in
            let imageTags = image.tags.map { $0.name.lowercased() }
            return tagNames.allSatisfy { tagName in
                imageTags.contains(where: { $0.contains(tagName.lowercased()) })
            }
        }
    }
}