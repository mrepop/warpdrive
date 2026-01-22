import SwiftUI

struct SessionListView: View {
    @ObservedObject var tmuxManager: TmuxManager
    @ObservedObject var sshClient: SSHClient
    
    @State private var isLoading = false
    @State private var showingNewSession = false
    @State private var newSessionName = ""
    @State private var errorMessage: String?
    @State private var selectedSession: TmuxSession?
    @State private var showingSettings = false
    @State private var hasAutoOpened = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(sshClient.connectionState.description)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    Button("Disconnect") {
                        sshClient.disconnect()
                        tmuxManager.disconnect()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            
            Section("tmux Sessions") {
                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading sessions...")
                            .foregroundColor(.secondary)
                    }
                } else if tmuxManager.sessions.isEmpty {
                    Text("No sessions found")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(tmuxManager.sessions) { session in
                        SessionRow(session: session)
                            .onTapGesture {
                                selectedSession = session
                            }
                    }
                }
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewSession = true }) {
                    Label("New Session", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    Task {
                        await refreshSessions()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .task {
            await refreshSessions()
            #if DEBUG
            if DebugConfig.autoOpenSession && !hasAutoOpened && !tmuxManager.sessions.isEmpty {
                hasAutoOpened = true
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    selectedSession = tmuxManager.sessions.first
                }
            }
            #endif
        }
        .alert("New Session", isPresented: $showingNewSession) {
            TextField("Session Name", text: $newSessionName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                createSession()
            }
            .disabled(newSessionName.isEmpty)
        } message: {
            Text("Enter a name for the new tmux session")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $selectedSession) { session in
            NavigationStack {
                #if os(iOS)
                SessionTabView(tmuxManager: tmuxManager, initialSession: session)
                #else
                SessionDetailView(session: session, tmuxManager: tmuxManager)
                #endif
            }
        }
    }
    
    @MainActor
    private func refreshSessions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await tmuxManager.listSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func createSession() {
        Task {
            do {
                _ = try await tmuxManager.createSession(name: newSessionName)
                newSessionName = ""
                await refreshSessions()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: TmuxSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.name)
                    .font(.headline)
                
                HStack {
                    Label("\(session.windows) window\(session.windows == 1 ? "" : "s")",
                          systemImage: "square.grid.2x2")
                    
                    if session.attached {
                        Label("Attached", systemImage: "link")
                            .foregroundColor(.green)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if let created = session.created {
                    Text("Created: \(created, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SessionListView(
            tmuxManager: TmuxManager(),
            sshClient: SSHClient()
        )
    }
}
