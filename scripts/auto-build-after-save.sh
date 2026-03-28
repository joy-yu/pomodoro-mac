#!/bin/bash

set -euo pipefail

SCHEME="Pomodoro"
CONFIGURATION="Debug"
DESTINATION="platform=macOS"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/$SCHEME.xcodeproj"
DERIVED_DATA_PATH="$PROJECT_ROOT/.xcode-build"

# 固定构建输出目录，确保每次覆盖同一路径下的产物
BUILD_SETTINGS=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION" -destination "$DESTINATION" -derivedDataPath "$DERIVED_DATA_PATH" -showBuildSettings)
BUILT_PRODUCTS_DIR=$(printf '%s\n' "$BUILD_SETTINGS" | awk -F ' = ' '/BUILT_PRODUCTS_DIR/ {print $2; exit}')
FULL_PRODUCT_NAME=$(printf '%s\n' "$BUILD_SETTINGS" | awk -F ' = ' '/FULL_PRODUCT_NAME/ {print $2; exit}')
APP_PATH="$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME"
APP_NAME="${FULL_PRODUCT_NAME%.app}"

# close old instance
pkill -x "$APP_NAME" || true

# build
xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION" -destination "$DESTINATION" -derivedDataPath "$DERIVED_DATA_PATH" build

if [[ ! -d "$APP_PATH" ]]; then
	echo "Built app not found at: $APP_PATH" >&2
	exit 1
fi



# run
open "$APP_PATH"
