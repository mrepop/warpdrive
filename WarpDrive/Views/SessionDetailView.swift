import SwiftUI

struct SessionDetailView: View {
    let session: TmuxSession
    @ObservedObject var tmuxManager: TmuxManager
    
    @State private var output: String = ""
    @State private var command: String = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Terminal output area
                ScrollView {
                    Text(output.isEmpty ? "Loading..." : output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color.black)
                .foregroundColor(.green)
                
                Divider()
                
                // Command input area
                HStack {
                    TextField("Enter command...", text: $command)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .onSubmit(sendCommand)
                    
                    Button(action: sendCommand) {
                        Image(systemName: "paperplane.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(command.isEmpty || isLoading)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
            .navigationTitle(session.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: refreshOutput) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button(role: .destructive, action: killSession) {
                            Label("Kill Session", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await loadOutput()
            }
        }
    }
    
    private func loadOutput() async {
        isLoading = true
        
        do {
            let captured = try await tmuxManager.capturePaneOutput(session: session, lines: 100)
            await MainActor.run {
                output = captured
            }
        } catch {
            await MainActor.run {
                output = "Error: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func refreshOutput() {
        Task {
            await loadOutput()
        }
    }
    
    private func sendCommand() {
        guard !command.isEmpty else { return }
        
        Task {
            do {
                // Send the command
                try await tmuxManager.sendKeys(command, session: session)
                // Send Enter key
                try await tmuxManager.sendKeys("Enter", session: session)
                
                await MainActor.run {
                    command = ""
                }
                
                // Wait a bit for command to execute
                try await Task.sleep(nanoseconds: 500_000_000)
                
                // Refresh output
                await loadOutput()
            } catch {
                await MainActor.run {
                    output += "\nError: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func killSession() {
        Task {
            do {
                try await tmuxManager.killSession(session)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    output += "\nError killing session: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    SessionDetailView(
        session: TmuxSession(id: "test", name: "test", created: Date(), attached: false, windows: 1),
        tmuxManager: TmuxManager()
    )
}
