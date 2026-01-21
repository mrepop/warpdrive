import SwiftUI

struct SessionDetailView: View {
    let session: TmuxSession
    @ObservedObject var tmuxManager: TmuxManager
    
    @State private var terminalController: TerminalViewController?
    @State private var command: String = ""
    @State private var isLoading = false
    @State private var autoRefreshTimer: Timer?
    @Environment(\.dismiss) private var dismiss
    
    #if os(iOS)
    @FocusState private var isInputFocused: Bool
    #endif
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Terminal view with SwiftTerm
                TerminalView(terminalController: $terminalController)
                    .background(Color.black)
                
                Divider()
                
                #if os(iOS)
                // Custom keyboard accessory for iOS
                TerminalKeyboardAccessory { key in
                    handleTerminalKey(key)
                }
                #endif
                
                // Command input area
                HStack {
                    TextField("Enter command...", text: $command)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .onSubmit(sendCommand)
                        #if os(iOS)
                        .focused($isInputFocused)
                        #endif
                    
                    Button(action: sendCommand) {
                        Image(systemName: "paperplane.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(command.isEmpty || isLoading)
                    
                    #if os(iOS)
                    // Copy button
                    Button(action: copySelectedText) {
                        Image(systemName: "doc.on.clipboard")
                    }
                    .buttonStyle(.bordered)
                    
                    // Paste button
                    Button(action: pasteText) {
                        Image(systemName: "doc.on.clipboard.fill")
                    }
                    .buttonStyle(.bordered)
                    #endif
                }
                .padding()
                #if os(macOS)
                .background(Color(NSColor.controlBackgroundColor))
                #else
                .background(Color(.systemBackground))
                #endif
            }
            .navigationTitle(session.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        stopAutoRefresh()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: refreshOutput) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: clearTerminal) {
                            Label("Clear", systemImage: "trash")
                        }
                        
                        Button(role: .destructive, action: killSession) {
                            Label("Kill Session", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await loadOutput()
                startAutoRefresh()
            }
        }
    }
    
    private func loadOutput() async {
        isLoading = true
        
        do {
            let captured = try await tmuxManager.capturePaneOutput(session: session, lines: 100)
            await MainActor.run {
                terminalController?.clear()
                terminalController?.feed(text: captured)
            }
        } catch {
            await MainActor.run {
                terminalController?.feed(text: "Error: \(error.localizedDescription)\n")
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
                    terminalController?.feed(text: "\nError: \(error.localizedDescription)\n")
                }
            }
        }
    }
    
    private func killSession() {
        Task {
            do {
                try await tmuxManager.killSession(session)
                await MainActor.run {
                    stopAutoRefresh()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    terminalController?.feed(text: "\nError killing session: \(error.localizedDescription)\n")
                }
            }
        }
    }
    
    #if os(iOS)
    private func handleTerminalKey(_ key: TerminalKey) {
        let sequence = key.escapeSequence
        guard !sequence.isEmpty else { return }
        
        Task {
            do {
                try await tmuxManager.sendKeys(sequence, session: session)
                
                // Refresh after a short delay
                try await Task.sleep(nanoseconds: 100_000_000)
                await loadOutput()
            } catch {
                await MainActor.run {
                    terminalController?.feed(text: "\nError: \(error.localizedDescription)\n")
                }
            }
        }
    }
    
    private func copySelectedText() {
        guard let selectedText = terminalController?.getSelectedText(), !selectedText.isEmpty else {
            return
        }
        
        UIPasteboard.general.string = selectedText
    }
    
    private func pasteText() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            return
        }
        
        Task {
            do {
                try await tmuxManager.sendKeys(text, session: session)
                
                // Refresh after paste
                try await Task.sleep(nanoseconds: 100_000_000)
                await loadOutput()
            } catch {
                await MainActor.run {
                    terminalController?.feed(text: "\nError: \(error.localizedDescription)\n")
                }
            }
        }
    }
    #endif
    
    private func clearTerminal() {
        terminalController?.clear()
    }
    
    private func startAutoRefresh() {
        // Auto-refresh terminal output every 2 seconds
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await loadOutput()
            }
        }
    }
    
    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
}

#Preview {
    SessionDetailView(
        session: TmuxSession(id: "test", name: "test", created: Date(), attached: false, windows: 1),
        tmuxManager: TmuxManager()
    )
}
