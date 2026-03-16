#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
# Terminal Alias Manager — Build & Package Script
# Creates a signed .app and a distributable .dmg
# ─────────────────────────────────────────────
# Usage:
#   chmod +x scripts/build-dmg.sh
#   ./scripts/build-dmg.sh
# ─────────────────────────────────────────────

APP_NAME="AliasManager"
SCHEME="AliasManager"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
VOLUME_NAME="${APP_NAME}"

echo "╔═══════════════════════════════════════════╗"
echo "║   Terminal Alias Manager — Build Script   ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# ── Step 1: Check dependencies ──────────────
echo "→ Checking dependencies..."

if ! command -v xcodebuild &> /dev/null; then
    echo "✗ Xcode is not installed. Install it from the App Store."
    exit 1
fi

if ! command -v create-dmg &> /dev/null; then
    echo "→ Installing create-dmg via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "✗ Homebrew is not installed."
        echo "  Install it from https://brew.sh and try again."
        exit 1
    fi
    brew install create-dmg
fi

echo "✓ All dependencies found"
echo ""

# ── Step 2: Clean previous build ────────────
echo "→ Cleaning previous build..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
echo "✓ Clean"
echo ""

# ── Step 3: Build the app ───────────────────
echo "→ Building ${APP_NAME}..."
xcodebuild \
    -project "${PROJECT_DIR}/${APP_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    archive \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    | tail -5

echo "✓ Archive complete"
echo ""

# ── Step 4: Export the .app ─────────────────
echo "→ Exporting ${APP_NAME}.app..."

# Create export options plist
cat > "${BUILD_DIR}/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF

# Try exporting with signing, fall back to direct copy if no signing identity
if xcodebuild -exportArchive \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    -exportPath "${BUILD_DIR}" \
    -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist" \
    2>/dev/null; then
    echo "✓ Exported with signing"
else
    echo "→ No Developer ID found, exporting without signing..."
    cp -R "${BUILD_DIR}/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app" "${APP_PATH}"
    echo "✓ Exported (unsigned)"
fi

# Verify .app exists
if [ ! -d "${APP_PATH}" ]; then
    echo "✗ Failed to create ${APP_NAME}.app"
    exit 1
fi

echo "✓ ${APP_NAME}.app ready"
echo ""

# ── Step 5: Create DMG ──────────────────────
echo "→ Creating ${DMG_NAME}..."

# Remove old DMG if exists
rm -f "${DMG_PATH}"

create-dmg \
    --volname "${VOLUME_NAME}" \
    --volicon "${PROJECT_DIR}/${APP_NAME}/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 180 190 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 480 190 \
    --no-internet-enable \
    "${DMG_PATH}" \
    "${APP_PATH}" \
    2>/dev/null || \
create-dmg \
    --volname "${VOLUME_NAME}" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 180 190 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 480 190 \
    --no-internet-enable \
    "${DMG_PATH}" \
    "${APP_PATH}"

echo ""
echo "✓ DMG created successfully!"
echo ""

# ── Done ────────────────────────────────────
DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
echo "╔═══════════════════════════════════════════╗"
echo "║              Build Complete!              ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
echo "  📦 App:  ${APP_PATH}"
echo "  💿 DMG:  ${DMG_PATH} (${DMG_SIZE})"
echo ""
echo "  To install: open ${DMG_PATH}"
echo "  Then drag AliasManager to Applications."
echo ""
