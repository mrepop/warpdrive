# WarpDrive Setup Guide

## Prerequisites

### System Requirements
- macOS 13.0+ (for development)
- iOS 17.0+ (for deployment)
- Xcode 26.0+
- Swift 5.9+

### Required Software
- **tmux**: Terminal multiplexer for session management
- **SSH server**: For remote connections

## Installation

### 1. Install tmux

Using Homebrew:
```bash
brew install tmux
```

Verify installation:
```bash
tmux -V
```

### 2. Configure SSH Access

#### Enable Remote Login (macOS)
1. Open System Settings > General > Sharing
2. Enable "Remote Login"
3. Configure access for your user account

#### Set Up SSH Keys

Generate SSH key if you don't have one:
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Add your public key to authorized_keys for localhost testing:
```bash
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Test SSH connection to localhost:
```bash
ssh localhost "echo 'SSH test successful'"
```

#### Configure SSH Agent

Ensure SSH agent is running:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

Add to `~/.zshrc` or `~/.bashrc` for persistence:
```bash
# Start SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_rsa 2>/dev/null
fi
```

### 3. Create Test tmux Sessions

Create a test session:
```bash
tmux new-session -d -s test-session
tmux send-keys -t test-session 'echo "Hello from WarpDrive"' Enter
```

List sessions:
```bash
tmux list-sessions
```

Attach to session:
```bash
tmux attach-session -t test-session
```

## Building the Project

### Command Line Build

```bash
cd warpdrive
swift build
```

### Run Tests

```bash
swift test
```

### Run Specific Tests

```bash
swift test --filter IntegrationTests
swift test --filter TmuxControlModeTests
```

### Open in Xcode

```bash
open Package.swift
```

Then in Xcode:
1. Select the WarpDrive scheme
2. Choose your target (My Mac or iOS Simulator)
3. Press Cmd+R to run

## Usage

### Connecting to a Server

1. Launch WarpDrive
2. Click "Connect to Server"
3. Enter connection details:
   - **Hostname**: localhost (for testing) or remote IP/hostname
   - **Port**: 22 (default SSH port)
   - **Username**: Your username
   - **Auth Method**: 
     - **SSH Agent**: Uses your configured SSH agent (recommended)
     - **Public Key**: Specify path to private key
     - **Password**: Enter password (less secure)
4. Click "Connect"

### Managing tmux Sessions

Once connected:
- **View Sessions**: See all available tmux sessions
- **Create Session**: Tap "+" to create a new session
- **Select Session**: Tap any session to view/control it
- **Delete Session**: Swipe left or use the menu

### Controlling a Session

In the session detail view:
- **View Output**: See the last 100 lines of terminal output
- **Send Commands**: Type in the command field and press Enter
- **Refresh**: Pull latest output from the session
- **Kill Session**: Permanently terminate the session

## Troubleshooting

### tmux not found

**Problem**: "tmux is not installed" error

**Solution**: 
1. Install tmux: `brew install tmux`
2. If tmux is installed but not in PATH, add to your shell RC file:
   ```bash
   export PATH="/opt/homebrew/bin:$PATH"
   ```

### SSH Connection Failed

**Problem**: Cannot connect to SSH server

**Solutions**:
1. Verify SSH server is running:
   ```bash
   sudo systemsetup -getremotelogin
   ```
2. Test SSH manually:
   ```bash
   ssh -v user@host
   ```
3. Check firewall settings
4. Verify SSH keys are properly configured

### Authentication Failed

**Problem**: "Authentication failed" error

**Solutions**:
1. Ensure SSH agent has your key:
   ```bash
   ssh-add -l
   ```
2. Add key if missing:
   ```bash
   ssh-add ~/.ssh/id_rsa
   ```
3. Try password authentication if key auth fails
4. Check file permissions:
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/id_rsa
   ```

### Session Not Found

**Problem**: Created session doesn't appear in list

**Solution**: This is a known issue in Phase 1. Each SSH command runs in a separate connection. For now, manually create sessions directly on the server:
```bash
tmux new-session -d -s my-session
```

## Development

### Project Structure

```
WarpDrive/
├── Network/           # SSH client and networking
│   ├── SSHClient.swift
│   ├── SSHModels.swift
├── Terminal/          # tmux integration
│   ├── TmuxManager.swift
│   ├── TmuxModels.swift
├── Utilities/         # Logging and helpers
│   └── Logger.swift
├── Views/             # SwiftUI user interface
│   ├── ContentView.swift
│   ├── ConnectionConfigView.swift
│   ├── SessionListView.swift
│   └── SessionDetailView.swift
└── App/               # App entry point
    └── WarpDriveApp.swift
```

### Running Tests

The project includes:
- **Unit Tests**: Test tmux protocol parsing
- **Integration Tests**: Test SSH and tmux operations

Note: Integration tests require SSH to be configured on localhost.

### Debugging

View logs using the built-in logger:
```swift
WarpLogger.shared.exportLogs()
```

Categories:
- `.ssh` - SSH connection logs
- `.tmux` - tmux operation logs
- `.terminal` - Terminal emulation logs
- `.network` - Network operations
- `.ui` - User interface events

## Next Steps

Phase 1 provides basic functionality. Future phases will add:
- Real-time terminal streaming (Phase 2)
- Bonjour/mDNS discovery (Phase 2)
- Full tmux control mode integration (Phase 2)
- Bridge server for advanced scenarios (Phase 3)
- Enhanced security features (Phase 4)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review logs for diagnostic information
3. Open an issue on GitHub with logs and error messages
