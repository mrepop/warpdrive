import Foundation
import Combine

@MainActor
class SessionManager: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var activeSession: Session?
    @Published var isConnected: Bool = false
    @Published var connectionError: String?
    
    init() {
        loadSessions()
    }
    
    func loadSessions() {
        // TODO: Load sessions from persistent storage
        sessions = []
    }
    
    func addSession(_ session: Session) {
        sessions.append(session)
        saveSessions()
    }
    
    func removeSession(_ session: Session) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }
    
    func connect(to session: Session) async throws {
        // TODO: Implement connection logic to Warp console
        connectionError = nil
        isConnected = true
        activeSession = session
    }
    
    func disconnect() {
        isConnected = false
        activeSession = nil
    }
    
    private func saveSessions() {
        // TODO: Persist sessions to storage
    }
}
