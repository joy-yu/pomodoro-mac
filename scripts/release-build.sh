#!/bin/bash
# Builds a release .app with ad-hoc signing and zips it to dist/

set -euo pipefail

SCHEME="Pomodoro"
CONFIGURATION="Release"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/$SCHEME.xcodeproj"
ARCHIVE_PATH="$PROJECT_ROOT/dist/$SCHEME.xcarchive"

# ── Warn if project.yml is newer than the generated .xcodeproj ──────────────
if [[ "$PROJECT_ROOT/project.yml" -nt "$PROJECT_PATH/project.pbxproj" ]]; then
    echo "⚠️  project.yml is newer than .xcodeproj — running xcodegen generate..." >&2
    xcodegen generate --spec "$PROJECT_ROOT/project.yml" --project "$PROJECT_ROOT"
fi

echo "==> Cleaning dist/"
rm -rf "$PROJECT_ROOT/dist"
mkdir -p "$PROJECT_ROOT/dist"

echo "==> Archiving ($CONFIGURATION, ad-hoc signing)..."
xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE=Manual \
    AD_HOC_CODE_SIGNING_ALLOWED=YES

if [[ ! -d "$ARCHIVE_PATH" ]]; then
    echo "Archive not found at: $ARCHIVE_PATH" >&2
    exit 1
fi

# Extract .app directly from the xcarchive (no exportArchive needed for ad-hoc)
APP_PATH=$(find "$ARCHIVE_PATH/Products/Applications" -name "*.app" -maxdepth 1 | head -1)
if [[ -z "$APP_PATH" ]]; then
    echo "App not found inside archive at: $ARCHIVE_PATH/Products/Applications" >&2
    exit 1
fi

APP_NAME=$(basename "$APP_PATH" .app)
VERSION=$(defaults read "$APP_PATH/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "unknown")
ZIP_PATH="$PROJECT_ROOT/dist/$APP_NAME-$VERSION.zip"

echo "==> Creating $APP_NAME-$VERSION.zip..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo ""
echo "Done."
echo "  Archive : $ARCHIVE_PATH"
echo "  App     : $APP_PATH"
echo "  Zip     : $ZIP_PATH"
