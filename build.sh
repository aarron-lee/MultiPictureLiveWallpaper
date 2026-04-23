#!/usr/bin/env bash
# Build MultiPictureLiveWallpaper APK
# Usage: ./build.sh [free|dnt] [debug|release]
set -euo pipefail

PROJECT="$(cd "$(dirname "$0")" && pwd)"

# ── Android SDK ────────────────────────────────────────────────────────────────
ANDROID_SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
if [ ! -d "$ANDROID_SDK" ]; then
    echo "ERROR: Android SDK not found."
    echo "Set ANDROID_SDK_ROOT or ANDROID_HOME to your SDK path, e.g.:"
    echo "  export ANDROID_SDK_ROOT=\$HOME/Android/Sdk"
    exit 1
fi
echo "sdk.dir=$ANDROID_SDK" > "$PROJECT/local.properties"

# ── Arguments ──────────────────────────────────────────────────────────────────
VARIANT="${1:-free}"
BUILD_TYPE="${2:-debug}"

if [[ "$VARIANT" != "free" && "$VARIANT" != "dnt" ]]; then
    echo "Usage: $0 [free|dnt] [debug|release]"
    exit 1
fi
if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
    echo "Usage: $0 [free|dnt] [debug|release]"
    exit 1
fi

# ── Gradle wrapper ─────────────────────────────────────────────────────────────
if [ ! -f "$PROJECT/gradlew" ]; then
    if command -v gradle &>/dev/null; then
        echo "Generating Gradle wrapper..."
        gradle -p "$PROJECT" wrapper --gradle-version=8.7
        chmod +x "$PROJECT/gradlew"
    else
        echo "ERROR: 'gradlew' not found and 'gradle' is not installed."
        echo ""
        echo "Install Gradle via one of:"
        echo "  SDKMAN:        sdk install gradle 8.7"
        echo "  Fedora/RHEL:   sudo dnf install gradle"
        echo "  Ubuntu/Debian: sudo apt install gradle"
        echo "  Homebrew:      brew install gradle"
        echo "  Or download:   https://gradle.org/install/"
        exit 1
    fi
fi

# ── Build ──────────────────────────────────────────────────────────────────────
BUILD_TYPE_CAP="${BUILD_TYPE^}"
TASK=":variant:${VARIANT}:assemble${BUILD_TYPE_CAP}"

echo "Building: variant=$VARIANT  type=$BUILD_TYPE"
"$PROJECT/gradlew" -p "$PROJECT" "$TASK"

# ── Output ─────────────────────────────────────────────────────────────────────
APK_DIR="$PROJECT/variant/$VARIANT/build/outputs/apk/$BUILD_TYPE"
echo ""
echo "Output APK(s):"
find "$APK_DIR" -name "*.apk" 2>/dev/null | while read -r apk; do
    echo "  $apk"
done
