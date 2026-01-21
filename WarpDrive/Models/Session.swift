import Foundation

struct Session: Identifiable, Codable {
    let id: UUID
    let name: String
    let host: String
    let port: Int
    var isActive: Bool
    let createdAt: Date
    var lastAccessedAt: Date
    
    init(id: UUID = UUID(), name: String, host: String, port: Int, isActive: Bool = false) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.isActive = isActive
        self.createdAt = Date()
        self.lastAccessedAt = Date()
    }
}

extension Session {
    static let sample = Session(
        name: "Local Development",
        host: "localhost",
        port: 8080,
        isActive: true
    )
}
