# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

WarpDrive is an iOS/macOS application for controlling and monitoring tmux terminal sessions via SSH. It uses SwiftTerm for terminal emulation and Citadel (wrapping NIO-SSH) for SSH connectivity on iOS.

## Key Commands

### Building
```bash
swift build
```

### Testing
```bash
# Run all tests
swift test

# Run specific test suites
swift test --filter IntegrationTests
swift test --filter TmuxControlModeTests
swift test --filter KeyboardEchoTests

# Note: Integration tests require SSH configured on localhost (see SETUP.md)
```

### Opening in Xcode
```bash
open Package.swift
```

### iOS Simulator Quick Start
```bash
# Boot simulator and run app
bash startup.sh
```

## Architecture

### Layer Structure

**Network Layer** (`WarpDrive/Network/`):
- `SSHClient.swift`: Main SSH client with platform-agnostic interface
- `SSHClient+iOS.swift`: iOS-specific implementation using Citadel library for RSA key authentication
- macOS uses process-based ssh command execution for development
- iOS implementation maintains persistent connection via Citadel.SSHClient

**Terminal Layer** (`WarpDrive/Terminal/`):
- `TmuxManager.swift`: Manages tmux sessions, discovers/creates/kills sessions, sends keys, captures pane output
- Dynamically discovers tmux path on remote host (Homebrew or system locations)
- Uses tmux format strings for session listing: `session_name|session_created|session_attached|session_windows`

**Service Layer** (`WarpDrive/Services/`):
- `SessionManager.swift`: High-level session management with persistence (TODO)

**View Layer** (`WarpDrive/Views/`):
- `TerminalView.swift`: SwiftUI wrapper around SwiftTerm's native TerminalView (UIKit on iOS, AppKit on macOS)
- `TerminalKeyboardAccessory.swift`: Custom iOS keyboard with terminal keys (ESC, TAB, arrows, F-keys)
- `SessionDetailView.swift`: Main terminal interface with immediate character echo and 300ms refresh polling

**Models** (`WarpDrive/Models/`):
- `Session.swift`: User session metadata
- `TerminalSettings.swift`: Configurable settings (font size 8-24pt, keyboard auto-hide)

### Critical Implementation Details

**Immediate Character Echo**: Uses `.onChange(of: command)` to feed characters to terminal immediately before server processing, eliminating input lag

**iOS Keyboard Configuration**: Must use `.textInputAutocapitalization(.never)` and `.keyboardType(.asciiCapable)` on TextField to prevent command corruption

**Terminal Refresh**: Currently 300ms polling via `capturePaneOutput()`. Real-time streaming planned for Phase 5

**SSH Authentication**: 
- iOS: RSA keys only via Citadel library
- macOS: SSH agent or key-based via system ssh command
- Password auth not supported in current macOS implementation

**tmux Control**: Uses standard tmux commands, not control mode (yet). Commands must be escaped properly for SSH execution

## Platform Differences

The codebase uses conditional compilation (`#if os(iOS)` / `#if os(macOS)`) extensively:
- SSH execution: iOS uses Citadel async API, macOS uses Process with ssh binary
- Terminal views: iOS uses UIViewRepresentable, macOS uses NSViewRepresentable
- SwiftTerm font handling differs between UIFont and NSFont

## Testing Strategy

Tests assume localhost SSH is configured with key-based authentication:
```bash
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Integration tests will fail without SSH access to localhost. Unit tests (TmuxControlModeTests, KeyboardEchoTests) don't require SSH.

## Current Phase Status

Phase 4 Complete (Terminal Usability):
- Immediate character echo
- iOS keyboard autocapitalization fix
- 300ms terminal refresh (reduced from 2s)
- Custom keyboard accessory with terminal keys

Next: Phase 5 will add real-time streaming to replace polling

## Common Patterns

**Logging**: Use `logInfo()`, `logDebug()`, `logWarning()`, `logError()` with category (`.ssh`, `.tmux`, `.terminal`, `.network`, `.ui`)

**Error Handling**: Custom error types (`SSHError`, `TmuxError`) with descriptive messages

**Async/Await**: All SSH and tmux operations are async, use `@MainActor` for UI-touching classes

**Command Escaping**: When sending commands to tmux via SSH, single quotes must be escaped: `replacingOccurrences(of: "'", with: "'\\\\''")"`

## Prerequisites for Development

```bash
# Install tmux
brew install tmux

# Configure SSH for localhost testing
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Test SSH connection
ssh localhost "echo 'SSH test successful'"
```

## Key Dependencies

- **SwiftTerm** (1.0.0+): Terminal emulator with VT100/Xterm support
- **Citadel** (0.11.0+): High-level SSH client for iOS/macOS (wraps SwiftNIO-SSH)
