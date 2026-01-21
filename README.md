# WarpDrive

An iOS application for controlling and monitoring Warp console sessions from your iPhone or iPad via tmux.

## Status

**Phase 3 Complete | Phase 4 In Progress**

WarpDrive now supports:
- SSH connection with RSA key authentication (iOS & macOS)
- tmux session discovery, creation, and management
- Full SwiftTerm terminal emulation with ANSI escape sequences
- Custom iOS keyboard with terminal keys (ESC, TAB, arrows, F-keys)
- Copy/paste functionality
- Multiple session tabs
- Immediate character echo for responsive typing
- Optimized terminal refresh (300ms) for better usability
- No auto-capitalization on iOS keyboard
- Customizable terminal font size (8-24pt)

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

### Current (Phases 1-4)
- SSH connection with RSA key authentication (iOS & macOS)
- tmux session discovery, creation, deletion, and management
- Full SwiftTerm terminal emulation with VT100/Xterm support
- Custom iOS keyboard accessory with:
  - Terminal control keys (ESC, TAB, CTRL, ALT)
  - Arrow keys and navigation (HOME, END, PGUP, PGDN)
  - Function keys (F1-F12)
- Immediate character echo for responsive input
- Fast terminal refresh (300ms polling)
- Copy/paste support
- Multiple session tabs
- iOS keyboard optimized for terminal (no auto-capitalization)
- Customizable terminal font size (8-24pt, default 10pt for phones)
- Comprehensive error handling and diagnostic logging
- Cross-platform (iOS & macOS)

### Coming Soon
- Real-time terminal streaming (replace polling)
- Bonjour/mDNS server discovery
- Session persistence across app restarts
- Touch gestures (pinch-to-zoom, swipe actions)
- Terminal themes and customization

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
