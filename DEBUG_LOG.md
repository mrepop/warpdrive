# WarpDrive Horizontal Scroll Fix - Debug Log

## Session: 2026-01-22

### Problem Statement
Terminal content has horizontal scrolling issues - text wraps incorrectly and scrolls horizontally during interaction/rotation.

### Approach
1. Use fixed terminal dimensions (40 cols × 20 rows) instead of dynamic font-shrinking
2. Add test pattern to visualize exactly what's rendering
3. Test with minimal code before adding complexity

### Current Status: BLOCKED
**Issue:** Test pattern not showing despite code being in place.

**What we've done:**
- Added test pattern injection in TerminalView.makeUIView (lines 171-196 of TerminalView.swift)
- Disabled loadOutput() in SessionDetailView (line 187)
- Disabled auto-open session in DebugConfig
- Terminal resize to 40 cols hardcoded (line 175 of TerminalView.swift)

**What we're seeing:**
- Screenshots show regular SSH prompts "mrepop@Michaels-MacBook-Pro ~ %"
- Test pattern not visible
- This happens even when SessionDetailView shouldn't be opened

**Mystery:**
Prompts are showing even though:
- loadOutput() is commented out
- auto-open is disabled
- No obvious code path should be feeding tmux output

**Next steps to investigate:**
1. Check what view is actually being displayed (might be session list, not terminal)
2. Look for hidden terminal views embedded in unexpected places
3. Create completely isolated minimal test view with just terminal + test pattern, no SSH/tmux
Wed Jan 21 21:47:32 EST 2026: Checking current app state - taking screenshot to identify which view is showing
Wed Jan 21 21:48:03 EST 2026: Setting up script logging to capture all terminal I/O
Wed Jan 21 21:48:23 EST 2026: Taking screenshot to analyze view hierarchy
Wed Jan 21 21:48:48 EST 2026: PAUSED - User requested pause
Wed Jan 21 21:50:08 EST 2026: RESUMED - Creating isolated test terminal view to bypass SSH/tmux complexity
Wed Jan 21 21:50:49 EST 2026: CRITICAL INSIGHT - Live tmux output is bleeding through despite disabled loadOutput(). Need to bypass SSH/tmux entirely for test.
Wed Jan 21 21:51:33 EST 2026: Created TestTerminalView.swift - isolated terminal with no SSH/tmux, fixed 40x24, 10pt font
Wed Jan 21 21:52:26 EST 2026: Modified ContentView and DebugConfig to show TestTerminalView. Building...
Wed Jan 21 21:52:47 EST 2026: Build failed - brace mismatch in ContentView. Fixing...
Wed Jan 21 21:53:38 EST 2026: Fixed ContentView structure. Building again...
Wed Jan 21 21:54:08 EST 2026: BUILD SUCCEEDED. Installing and launching test terminal...
Wed Jan 21 21:54:29 EST 2026: Taking screenshot of test terminal...
Wed Jan 21 21:54:47 EST 2026: CRITICAL: Max safe image size is 1568px. Updating resize threshold to 1500px
Wed Jan 21 21:55:12 EST 2026: PROBLEM - TestTerminalView not showing, seeing normal ContentView instead. showTestTerminal flag may not be working.
Wed Jan 21 21:55:38 EST 2026: Checking if TestTerminalView has #if os(iOS) wrapper preventing it from showing...
Wed Jan 21 21:55:52 EST 2026: Checking end of TestTerminalView.swift...
Wed Jan 21 21:56:06 EST 2026: Issue - ContentView references TestTerminalView without checking iOS availability. Need to wrap ContentView check too.
Wed Jan 21 21:56:33 EST 2026: Added os(iOS) check. Rebuilding...
Wed Jan 21 21:56:55 EST 2026: Build succeeded. Installing and launching...
Wed Jan 21 21:57:26 EST 2026: STILL showing normal ContentView, not TestTerminalView. The conditional isn't working. Checking if #if DEBUG && os(iOS) syntax is valid...
Wed Jan 21 21:57:53 EST 2026: Fixed conditional to nested #if. Rebuilding...
Wed Jan 21 21:58:14 EST 2026: Build succeeded. Launching...
Wed Jan 21 22:02:09 EST 2026: CRASH RECOVERY - API crashed on image >2000px. Must resize BEFORE reading. Checking screenshot size...
Wed Jan 21 22:02:48 EST 2026: Screenshot is 1206px - safe to read
Wed Jan 21 22:03:11 EST 2026: PROBLEM - TestTerminalView NOT showing. Seeing normal ContentView (disconnected screen). The showTestTerminal flag isn't working. Need to debug why.
Wed Jan 21 22:03:48 EST 2026: Adding debug print to ContentView to trace which code path is executing...
Wed Jan 21 22:04:33 EST 2026: Added logging. Rebuilding...
Wed Jan 21 22:04:54 EST 2026: Launching with logging...
Wed Jan 21 22:05:10 EST 2026: Checking system logs...
Wed Jan 21 22:05:24 EST 2026: Simplifying - removing nested conditionals, making it always show TestTerminalView in DEBUG mode
Wed Jan 21 22:05:51 EST 2026: Simplified to unconditional test view. Rebuilding...
Wed Jan 21 22:06:11 EST 2026: Installing and launching...
Wed Jan 21 22:06:30 EST 2026: Taking screenshot...
Wed Jan 21 22:06:55 EST 2026: STILL showing normalContent. The #if DEBUG && os(iOS) conditional is NOT working. This means either: 1) Build is Release not Debug, 2) Compiler doesn't support && in #if, 3) Something else is wrong
Wed Jan 21 22:07:24 EST 2026: Fixed to nested #if. Rebuilding and testing...
Wed Jan 21 22:14:57 EST 2026: SAFETY UPDATE - Max image size set to 1000x1000. Must check/resize before ALL reads.
Wed Jan 21 22:15:22 EST 2026: SAFETY UPDATE - Max image size set to 1000x1000. Must check/resize before ALL reads.

Wed Jan 21 22:18:12 EST 2026: CRASH RECOVERY STATE
API crashed again due to image >2000px (actual limit is 1000px max).
Error: Anthropic API 400 - Image dimensions exceed max allowed size for many-image requests: 2000 pixels
Action taken: Set max image size to 1000x1000px for all future reads.
Status: Work paused until image size bug can be reliably prevented.
Next session: Must implement mandatory resize check before ANY image read.

