import SwiftUI

public struct ContentView: View {
    public init() {}
    @StateObject private var sshClient = SSHClient()
    @StateObject private var tmuxManager = TmuxManager()
    @State private var showingConnection = false
    @State private var isConnecting = false
    @State private var hasAutoConnected = false
    
    public var body: some View {
        #if DEBUG
        #if os(iOS)
        TestTerminalView()
        #else
        normalContent
        #endif
        #else
        normalContent
        #endif
    }
    
    private var normalContent: some View {
        NavigationStack {
            if sshClient.connectionState.isConnected {
                SessionListView(tmuxManager: tmuxManager, sshClient: sshClient)
            } else {
                VStack {
                    Image(systemName: "terminal.fill")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                        .font(.system(size: 72))
                        .padding()
                    
                    Text("WarpDrive")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Control your Warp sessions from anywhere")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Text(sshClient.connectionState.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom)
                    
                    Spacer()
                    
                    Button(action: {
                        showingConnection = true
                    }) {
                        Label("Connect to Server", systemImage: "link")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .disabled(isConnecting)
                }
                .navigationTitle("WarpDrive")
                .padding()
                .sheet(isPresented: $showingConnection) {
                    ConnectionConfigView(sshClient: sshClient, tmuxManager: tmuxManager)
                }
                .task {
                    #if DEBUG
                    if DebugConfig.autoConnect && !hasAutoConnected {
                        hasAutoConnected = true
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await autoConnect()
                    }
                    #endif
                }
            }
        }
    }
    
    #if DEBUG
    private func autoConnect() async {
        do {
            let credentials = SSHCredentials(
                username: DebugConfig.username,
                authMethod: DebugConfig.usePassword ? 
                    .password(DebugConfig.password) : 
                    .publicKey(privateKeyPath: "~/.ssh/id_rsa", passphrase: nil)
            )
            let config = SSHConnectionConfig(
                host: DebugConfig.hostname,
                port: DebugConfig.port,
                credentials: credentials
            )
            try await sshClient.connect(config: config)
            tmuxManager.connect(sshClient: sshClient)
        } catch {
            print("Debug auto-connect failed: \(error)")
        }
    }
    #endif
}

#Preview {
    ContentView()
}
