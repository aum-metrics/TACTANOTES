#!/bin/bash
set -e # Exit on error

echo "🔧 TACTANOTES: Starting Auto-Repair..."

# 1. Source Rust Environment (in case it's not loaded)
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# 2. Fix Gap 6: Platform Folders
echo "📱 Gap 6: Regenerating Android/iOS folders..."
if [ -d "tactanotes_ui" ]; then
    cd tactanotes_ui
    flutter create . --platforms=android,ios
    cd ..
else
    echo "❌ Error: 'tactanotes_ui' directory not found!"
    exit 1
fi

# 3. Fix Gap 1: Bridge Generation (Glue)
echo "🌉 Gap 1: Generating Rust Bridge..."
# Ensure codegen is installed
if ! command -v flutter_rust_bridge_codegen &> /dev/null; then
    echo "📦 Installing flutter_rust_bridge_codegen..."
    cargo install flutter_rust_bridge_codegen
fi

# Run Generation
flutter_rust_bridge_codegen generate \
    --rust-root tactanotes_core \
    --rust-input crate::api \
    --dart-output tactanotes_ui/lib/src/rust

echo "✅ REPAIR COMPLETE!"
echo "🚀 You can now run: cd tactanotes_ui && flutter run"
