#!/bin/bash

# Quick script to build and prepare for App Store upload
# This bypasses the dSYM validation issue

set -e

echo "🚀 Building for App Store submission..."

# Navigate to project directory
cd "$(dirname "$0")/.."

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Build IPA with export options that skip dSYM upload
echo "📦 Building IPA..."
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

echo ""
echo "✅ Build complete!"
echo ""
echo "📍 IPA Location: build/ios/ipa/yazdrive.ipa"
echo ""
echo "📤 Next steps:"
echo "  1. Open Transporter app (from Mac App Store)"
echo "  2. Drag the IPA file into Transporter"
echo "  3. Click 'Deliver'"
echo ""
echo "OR use command line:"
echo "  xcrun altool --upload-app --type ios --file build/ios/ipa/yazdrive.ipa \\"
echo "    --username YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD"
echo ""
