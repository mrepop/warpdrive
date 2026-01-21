import SwiftUI

/// Tab-based view for managing multiple active terminal sessions
struct SessionTabView: View {
    @ObservedObject var tmuxManager: TmuxManager
    let initialSession: TmuxSession?
    @State private var activeSessions: [ActiveSession] = []
    @State private var selectedSessionId: UUID?
    @State private var showSessionPicker = false
    
    struct ActiveSession: Identifiable {
        let id = UUID()
        let session: TmuxSession
        var terminalController: TerminalViewController?
    }
    
    var body: some View {
        ZStack {
            // Content area - show selected session's terminal
            if let activeSession = activeSessions.first(where: { $0.id == selectedSessionId }) {
                SessionDetailView(session: activeSession.session, tmuxManager: tmuxManager)
            } else if activeSessions.isEmpty {
                Text("No active sessions")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            } else {
                Text("Select a session")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            }
            
            // Floating session picker button (top-right, only if multiple sessions)
            if activeSessions.count > 1 {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showSessionPicker = true }) {
                            HStack(spacing: 4) {
                                Text(activeSessions.first(where: { $0.id == selectedSessionId })?.session.name ?? "Session")
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                Image(systemName: "chevron.down.circle.fill")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSessionPicker) {
            SessionPickerSheet(
                sessions: activeSessions,
                selectedId: $selectedSessionId,
                onClose: { id in closeSession(id) }
            )
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

/// Session picker sheet for switching between sessions
private struct SessionPickerSheet: View {
    let sessions: [SessionTabView.ActiveSession]
    @Binding var selectedId: UUID?
    let onClose: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sessions) { session in
                    Button(action: {
                        selectedId = session.id
                        dismiss()
                    }) {
                        HStack {
                            Text(session.session.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedId == session.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        onClose(sessions[index].id)
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SessionTabView(tmuxManager: TmuxManager(), initialSession: nil)
}
