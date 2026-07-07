#!/bin/bash
# SmartGateBD - Generate Keystore & Build Release
# Run this script from: /Volumes/Project/Client Project/SmartGateBD/society_user

set -e

echo "========================================="
echo "SmartGateBD Release Build Script"
echo "========================================="

# Step 1: Check/Install Java
echo ""
echo "Step 1: Checking Java installation..."
if ! command -v java &> /dev/null; then
    echo "❌ Java not found. Installing Java 21 (Temurin)..."
    echo "This will require your sudo password."
    brew install temurin@21 || {
        echo "❌ Java installation failed."
        echo "Alternative: Download from https://adoptium.net/temurin/"
        exit 1
    }
fi

# Verify Java
java_version=$(java -version 2>&1 | head -1)
echo "✅ Java ready: $java_version"

# Step 2: Generate Keystore
echo ""
echo "Step 2: Generating keystore (if not exists)..."
if [ -f "android/app/smartgatebd.jks" ]; then
    echo "✅ Keystore already exists: android/app/smartgatebd.jks"
else
    echo "🔨 Creating new keystore..."
    keytool -genkeypair -v \
        -keystore android/app/smartgatebd.jks \
        -alias smartgatebd \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass smartgatebd \
        -keypass smartgatebd \
        -dname "CN=SmartGateBD, OU=SmartGateBD, O=SmartGateBD, L=Dhaka, S=Dhaka, C=BD"
    
    if [ -f "android/app/smartgatebd.jks" ]; then
        echo "✅ Keystore created successfully!"
        ls -lh android/app/smartgatebd.jks
    else
        echo "❌ Keystore creation failed"
        exit 1
    fi
fi

# Step 3: Build Release AAB
echo ""
echo "Step 3: Building release Android App Bundle (AAB)..."
echo "This may take 3-5 minutes..."

flutter clean
flutter pub get
flutter build appbundle --release

# Step 4: Verify output
echo ""
echo "Step 4: Verifying build output..."
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    aab_size=$(ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print $5}')
    echo "✅ Build successful!"
    echo "📦 Release AAB: build/app/outputs/bundle/release/app-release.aab ($aab_size)"
    echo ""
    echo "========================================="
    echo "🎉 Ready for Play Store upload!"
    echo "========================================="
    echo ""
    echo "Next steps:"
    echo "1. Open Google Play Console: https://play.google.com/console"
    echo "2. Select your app (SmartGateBD - User)"
    echo "3. Go to Release → Production"
    echo "4. Create new release and upload the AAB"
    echo ""
else
    echo "❌ Build failed. Check errors above."
    exit 1
fi
