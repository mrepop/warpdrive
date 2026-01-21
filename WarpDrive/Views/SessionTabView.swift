import SwiftUI

/// Tab-based view for managing multiple active terminal sessions
struct SessionTabView: View {
    @ObservedObject var tmuxManager: TmuxManager
    let initialSession: TmuxSession?
    @State private var activeSessions: [ActiveSession] = []
    @State private var selectedSessionId: UUID?
    
    struct ActiveSession: Identifiable {
        let id = UUID()
        let session: TmuxSession
        var terminalController: TerminalViewController?
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            if !activeSessions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(activeSessions) { activeSession in
                            TabButton(
                                title: activeSession.session.name,
                                isSelected: selectedSessionId == activeSession.id,
                                onSelect: {
                                    selectedSessionId = activeSession.id
                                },
                                onClose: {
                                    closeSession(activeSession.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .frame(height: 44)
                #if os(iOS)
                .background(Color(.systemGray6))
                #else
                .background(Color(NSColor.controlBackgroundColor))
                #endif
                
                Divider()
            }
            
            // Content area - show selected session's terminal
            if let activeSession = activeSessions.first(where: { $0.id == selectedSessionId }) {
                SessionDetailView(session: activeSession.session, tmuxManager: tmuxManager)
            } else if activeSessions.isEmpty {
                Text("No active sessions")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Select a session")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // Open initial session if provided
            if let session = initialSession, activeSessions.isEmpty {
                print("🔧 DEBUG: SessionTabView opening initial session: \(session.name)")
                openSession(session)
            }
        }
    }
    
    func openSession(_ session: TmuxSession) {
        // Check if session is already open
        if activeSessions.contains(where: { $0.session.id == session.id }) {
            // Switch to it
            if let existingSession = activeSessions.first(where: { $0.session.id == session.id }) {
                selectedSessionId = existingSession.id
            }
        } else {
            // Open new session
            let newSession = ActiveSession(session: session, terminalController: nil)
            activeSessions.append(newSession)
            selectedSessionId = newSession.id
        }
    }
    
    func closeSession(_ id: UUID) {
        activeSessions.removeAll { $0.id == id }
        
        // Select another session if available
        if selectedSessionId == id {
            selectedSessionId = activeSessions.first?.id
        }
    }
}

/// Individual tab button
private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: onSelect) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                #if os(iOS)
                .fill(isSelected ? Color(.systemGray4) : Color(.systemGray5))
                #else
                .fill(isSelected ? Color(NSColor.controlBackgroundColor) : Color(NSColor.textBackgroundColor))
                #endif
        )
    }
}

#Preview {
    SessionTabView(tmuxManager: TmuxManager(), initialSession: nil)
}
