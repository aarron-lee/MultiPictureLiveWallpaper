#!/usr/bin/env bash
# Build MultiPictureLiveWallpaper debug APK
# Usage: ./build.sh [free|dnt]
set -euo pipefail

PROJECT="$(cd "$(dirname "$0")" && pwd)"

# ── Java ───────────────────────────────────────────────────────────────────────
# Gradle 8.x requires Java 17-21. Prefer the Android Studio bundled JBR if
# present, since the system Java may be too new (Java 22+ breaks Gradle 8.x).
find_java() {
    local candidates=(
        "$HOME/Development/android-studio/jbr"
        "$HOME/android-studio/jbr"
        "/opt/android-studio/jbr"
        "/usr/local/android-studio/jbr"
    )
    for dir in "${candidates[@]}"; do
        if [ -x "$dir/bin/java" ]; then
            echo "$dir"
            return
        fi
    done
}

if [ -z "${JAVA_HOME:-}" ]; then
    jbr="$(find_java)"
    if [ -n "$jbr" ]; then
        export JAVA_HOME="$jbr"
    else
        # Fall back to system Java and warn if version is too new
        java_ver="$("${JAVA_HOME:-}/bin/java" -version 2>&1 | awk -F'"' '/version/{print $2}' | cut -d. -f1)"
        if [ "${java_ver:-0}" -gt 21 ] 2>/dev/null; then
            echo "WARNING: Java $java_ver detected. Gradle 8.x works best with Java 17-21."
            echo "Set JAVA_HOME to a Java 17-21 installation to avoid build errors."
        fi
    fi
fi

# ── Android SDK ────────────────────────────────────────────────────────────────
ANDROID_SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
if [ ! -d "$ANDROID_SDK" ]; then
    echo "ERROR: Android SDK not found."
    echo "Set ANDROID_SDK_ROOT or ANDROID_HOME, e.g.:  export ANDROID_SDK_ROOT=\$HOME/Android/Sdk"
    exit 1
fi
echo "sdk.dir=$ANDROID_SDK" > "$PROJECT/local.properties"

# ── Argument ───────────────────────────────────────────────────────────────────
VARIANT="${1:-free}"
if [[ "$VARIANT" != "free" && "$VARIANT" != "dnt" ]]; then
    echo "Usage: $0 [free|dnt]"
    exit 1
fi

# ── Gradle wrapper ─────────────────────────────────────────────────────────────
if [ ! -f "$PROJECT/gradlew" ]; then
    if command -v gradle &>/dev/null; then
        echo "Generating Gradle wrapper..."
        gradle -p "$PROJECT" wrapper --gradle-version=8.13
        chmod +x "$PROJECT/gradlew"
    else
        echo "ERROR: gradlew not found and gradle is not installed."
        echo "Install via SDKMAN: sdk install gradle 8.13"
        exit 1
    fi
fi

# ── Build ──────────────────────────────────────────────────────────────────────
echo "Building $VARIANT debug APK  (JAVA_HOME=${JAVA_HOME:-system})"
"$PROJECT/gradlew" -p "$PROJECT" ":variant:${VARIANT}:assembleDebug"

# ── Output ─────────────────────────────────────────────────────────────────────
APK_DIR="$PROJECT/variant/$VARIANT/build/outputs/apk/debug"
echo ""
echo "APK:"
find "$APK_DIR" -name "*.apk" | while read -r apk; do
    echo "  $apk"
done
