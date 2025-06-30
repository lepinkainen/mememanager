import Foundation

struct MemeImage: Identifiable, Codable {
    let databaseId: Int?
    let filename: String
    let originalName: String
    let path: String
    let createdDate: Date
    let updatedDate: Date
    
    var tags: [Tag] = []
    
    // Identifiable conformance using filename as unique identifier
    var id: String { filename }
    
    private enum CodingKeys: String, CodingKey {
        case databaseId = "id"
        case filename, originalName, path, createdDate, updatedDate
    }
}