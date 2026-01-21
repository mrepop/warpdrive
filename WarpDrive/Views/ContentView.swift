import SwiftUI

struct ContentView: View {
    @StateObject private var sshClient = SSHClient()
    @StateObject private var tmuxManager = TmuxManager()
    @State private var showingConnection = false
    @State private var isConnecting = false
    
    var body: some View {
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
            }
        }
    }
}

#Preview {
    ContentView()
}
