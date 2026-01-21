import SwiftUI

struct ConnectionConfigView: View {
    @ObservedObject var sshClient: SSHClient
    @ObservedObject var tmuxManager: TmuxManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var host: String = "localhost"
    @State private var port: String = "22"
    @State private var username: String = ProcessInfo.processInfo.environment["USER"] ?? ""
    #if os(iOS)
    @State private var authMethod: AuthMethodSelection = .publicKey
    #else
    @State private var authMethod: AuthMethodSelection = .agent
    #endif
    @State private var privateKeyPath: String = "~/.ssh/id_rsa"
    @State private var password: String = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    
    enum AuthMethodSelection: String, CaseIterable, Identifiable {
        case agent = "SSH Agent"
        case publicKey = "Public Key"
        case password = "Password"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("Hostname", text: $host)
                        .autocorrectionDisabled()
                    
                    TextField("Port", text: $port)
                    
                    TextField("Username", text: $username)
                        .autocorrectionDisabled()
                }
                
                Section("Authentication") {
                    Picker("Method", selection: $authMethod) {
                        ForEach(AuthMethodSelection.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    
                    switch authMethod {
                    case .publicKey:
                        TextField("Private Key Path", text: $privateKeyPath)
                            .autocorrectionDisabled()
                    case .password:
                        SecureField("Password", text: $password)
                    case .agent:
                        Text("Using SSH agent for authentication")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: connect) {
                        if isConnecting {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("Connecting...")
                            }
                        } else {
                            Text("Connect")
                        }
                    }
                    .disabled(isConnecting || host.isEmpty || username.isEmpty)
                }
            }
            .navigationTitle("SSH Connection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func connect() {
        isConnecting = true
        errorMessage = nil
        
        Task {
            do {
                let portInt = Int(port) ?? 22
                
                let authMethodConfig: SSHCredentials.AuthMethod
                switch authMethod {
                case .agent:
                    authMethodConfig = .agent
                case .publicKey:
                    let expandedPath = (privateKeyPath as NSString).expandingTildeInPath
                    authMethodConfig = .publicKey(privateKeyPath: expandedPath, passphrase: nil)
                case .password:
                    authMethodConfig = .password(password)
                }
                
                let credentials = SSHCredentials(username: username, authMethod: authMethodConfig)
                let config = SSHConnectionConfig(host: host, port: portInt, credentials: credentials)
                
                try await sshClient.connect(config: config)
                
                // Connect tmux manager
                await MainActor.run {
                    tmuxManager.connect(sshClient: sshClient)
                }
                
                // Dismiss on success
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isConnecting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ConnectionConfigView(
        sshClient: SSHClient(),
        tmuxManager: TmuxManager()
    )
}
