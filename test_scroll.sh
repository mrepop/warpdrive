#!/bin/bash
set -e

DEVICE="iPhone 17 Pro"
OUTPUT_DIR="/tmp/warpdrive_scroll_test"

mkdir -p "$OUTPUT_DIR"

echo "=== WarpDrive Horizontal Scroll Test ==="
echo ""

# Wait for app to fully load
echo "1. Waiting for app to load..."
sleep 6

# Portrait baseline
echo "2. Capturing portrait baseline..."
xcrun simctl io booted screenshot "$OUTPUT_DIR/01_portrait_baseline.png"

# Tap terminal area
echo "3. Tapping terminal to focus..."
xcrun simctl ui booted tap 360 400
sleep 1
xcrun simctl io booted screenshot "$OUTPUT_DIR/02_after_tap.png"

# Swipe left (horizontal) to trigger potential horizontal scroll
echo "4. Swiping left to test horizontal scroll..."
xcrun simctl ui booted swipe 600 400 100 400
sleep 1
xcrun simctl io booted screenshot "$OUTPUT_DIR/03_after_swipe_left.png"

# Swipe right
echo "5. Swiping right..."
xcrun simctl ui booted swipe 100 400 600 400
sleep 1
xcrun simctl io booted screenshot "$OUTPUT_DIR/04_after_swipe_right.png"

# Final state
echo "6. Capturing final state..."
sleep 1
xcrun simctl io booted screenshot "$OUTPUT_DIR/05_final.png"

echo ""
echo "=== Test Complete ==="
echo "Screenshots saved to: $OUTPUT_DIR"
echo ""
echo "Check the scroll offset monitor (top-right corner):"
echo "  - GREEN with X:0 = NO horizontal scroll (GOOD)"
echo "  - RED with X:>0 = horizontal scroll detected (BAD)"
echo ""
ls -1 "$OUTPUT_DIR"/*.png
