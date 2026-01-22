import Foundation

struct DebugConfig {
    static let autoConnect = false
    static let hostname = "localhost"
    static let port = 22
    static let username = "mrepop"
    
    // Using password auth for simulator testing
    static let usePassword = true
    static let password = "Manga&Anime1"
    
    // Auto-open first session
    static let autoOpenSession = false
    
    // Force software keyboard to show via hidden bridge TextField during debugging
static let forceSoftwareKeyboard = false
    static let fitDebug = true
    
    // Show isolated test terminal instead of normal app flow
    static let showTestTerminal = true
}
