#!/bin/bash
set -e

echo "🧪 TACTANOTES E2E VERIFICATION SUITE"
echo "====================================="

echo "🦀 1. Testing Rust Kernel (Backend)..."
cd tactanotes_core
cargo test --release -- --nocapture
cd ..
echo "✅ Backend Verified."

echo "🦋 2. Testing Flutter UI (Frontend)..."
cd tactanotes_ui
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter CLI not found. Please ensure Flutter is in your PATH."
    exit 1
fi

flutter pub get
flutter test
echo "✅ Frontend Verified."

echo "====================================="
echo "🎉 ALL SYSTEMS GO. READY FOR DEPLOYMENT."
