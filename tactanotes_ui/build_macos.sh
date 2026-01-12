#!/bin/bash

# Exit on error
set -e

# Ensure Homebrew Ruby and CocoaPods are in PATH
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"

echo "🚀 Starting thorough cleanup for macOS build (Signing Bypassed + Rust Linking)..."

# 1. Clean detritus
echo "🧹 Merging and removing AppleDouble detritus (dot_clean)..."
dot_clean .
xattr -cr .

# 1.2 Kill Zombies
echo "💀 Killing existing instances..."
killall tactanotes_ui || true

# 1.3 Nuke DerivedData (The Nuclear Option)
echo "☢️  Nuking Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner*

# 1.5 Generate Bridge
echo "🌉 Generating Flutter Rust Bridge bindings..."
flutter_rust_bridge_codegen generate --rust-root ../tactanotes_core --rust-input crate::api --dart-output lib/src/rust

# 2. Build Rust Library
echo "🏗️  Building Rust Core Library..."
cd ../tactanotes_core
echo "🧹 Cleaning Rust cargo..."
cargo clean
cargo build --lib
cd ../tactanotes_ui

# 3. Clean Flutter
echo "🧹 Running flutter clean..."
flutter clean
rm -rf build/macos
rm -rf macos/Pods
rm -rf macos/.symlinks

# 4. Build Flutter macOS app
echo "🏗️  Building macOS app (Debug)..."
flutter build macos --debug

# 5. Inject Rust Library into App Bundle
# We create the framework structure expected by the error we saw
APP_PATH="build/macos/Build/Products/Debug/tactanotes_ui.app"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
RUST_LIB_SRC="../tactanotes_core/target/debug/libtactanotes_core.dylib"

echo "💉 Injecting Rust Library into Bundle..."
mkdir -p "$FRAMEWORKS_DIR/tactanotes_core.framework"

# IMPORTANT: Copy the dylib as the framework binary
cp "$RUST_LIB_SRC" "$FRAMEWORKS_DIR/tactanotes_core.framework/tactanotes_core"

# Verify Checksums
echo "🔍 Verifying binary integrity..."
MD5_SRC=$(md5 -q "$RUST_LIB_SRC")
MD5_DEST=$(md5 -q "$FRAMEWORKS_DIR/tactanotes_core.framework/tactanotes_core")

echo "Source MD5: $MD5_SRC"
echo "Destin MD5: $MD5_DEST"

if [ "$MD5_SRC" != "$MD5_DEST" ]; then
    echo "❌ FATAL: Checksum mismatch! The library was not copied correctly."
    exit 1
fi

# Remove attributes from the injected lib
xattr -cr "$FRAMEWORKS_DIR/tactanotes_core.framework/tactanotes_core"

echo "✅ Build and Injection successful!"
echo "🚀 Try running: open $APP_PATH"
