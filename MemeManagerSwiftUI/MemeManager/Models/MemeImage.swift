import Foundation

struct MemeImage: Identifiable, Codable {
    let id: Int?
    let filename: String
    let originalName: String
    let path: String
    let createdDate: Date
    let updatedDate: Date
    
    var tags: [Tag] = []
}