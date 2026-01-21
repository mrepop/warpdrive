# WarpDrive

An iOS application for controlling and monitoring Warp console sessions from your iPhone or iPad via tmux.

## Status

**Phase 1 Complete!** 

WarpDrive now supports:
- SSH connection to remote servers
- tmux session listing and management
- Terminal output viewing
- Command execution in sessions
- Session creation and deletion
- Full diagnostic logging

## Quick Start

See [SETUP.md](SETUP.md) for detailed installation and configuration instructions.

### Prerequisites
```bash
# Install tmux
brew install tmux

# Configure SSH keys for localhost
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

### Build & Run
```bash
swift build
swift test
open Package.swift  # Opens in Xcode
```

## Features

### Current (Phase 1)
- SSH connection with key-based authentication
- tmux session discovery and listing
- View terminal output (last 100 lines)
- Send commands to sessions
- Create and delete sessions
- Comprehensive error handling and logging

### Coming Soon
- Real-time terminal streaming
- Full terminal emulation with SwiftTerm
- Bonjour/mDNS server discovery
- Bridge server for advanced scenarios
- Enhanced security features

## Requirements

- iOS 17.0+
- Xcode 26.0+
- Swift 5.9+

## Project Structure

```
WarpDrive/
├── WarpDrive/              # Main application code
│   ├── App/                # App lifecycle and configuration
│   ├── Views/              # SwiftUI views
│   ├── Models/             # Data models
│   ├── ViewModels/         # View models
│   ├── Services/           # Network and business logic
│   └── Resources/          # Assets and resources
├── WarpDriveTests/         # Unit tests
└── WarpDriveUITests/       # UI tests
```

## Getting Started

1. Clone the repository
2. Open `WarpDrive.xcodeproj` in Xcode
3. Build and run the project

## License

MIT
