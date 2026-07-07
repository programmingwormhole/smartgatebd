# SmartGateBD User App - Play Store Release Checklist

## ✅ Completed Configuration

- [x] Android signing config in `build.gradle.kts`
- [x] `key.properties` file created at `android/key.properties`
- [x] Release build config with minification enabled
- [x] App icons configured
- [x] Firebase configuration complete
- [x] AndroidManifest.xml updated

## 🔑 Step 1: Generate Keystore (One-time setup)

Run this command from the project root (`SmartGateBD/society_user`):

```bash
keytool -genkeypair -v -keystore android/app/smartgatebd.jks \
  -alias smartgatebd \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass smartgatebd \
  -keypass smartgatebd \
  -dname "CN=SmartGateBD, OU=SmartGateBD, O=SmartGateBD, L=Dhaka, S=Dhaka, C=BD"
```

**Note:** If you don't have Java/keytool:
- Install via Homebrew: `brew install temurin@21` (or openjdk@21)
- After installation, add Java to PATH if needed

Verify keystore was created:
```bash
ls -lh android/app/smartgatebd.jks
```

## 📦 Step 2: Build Release AAB (Android App Bundle)

From `SmartGateBD/society_user/`:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The release AAB will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

## 📱 Step 3: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (SmartGateBD - User)
3. Navigate to **Release** → **Production** (or Internal/Staging first for testing)
4. Click **Create new release**
5. Upload the AAB file from `build/app/outputs/bundle/release/app-release.aab`
6. Fill in release notes and confirm
7. Review and publish

## 📋 Pre-Release Checklist

Before uploading to Play Store:

- [ ] Version code incremented in `pubspec.yaml` (e.g., 1.0.0+2)
- [ ] App tested on multiple devices/Android versions (min SDK 21)
- [ ] All permissions in AndroidManifest.xml are justified
- [ ] Privacy policy URL ready for Play Store listing
- [ ] App screenshots (min 2, up to 8) in 16:9 or 20:9 aspect ratio
- [ ] Promotional banner image (1024x500 px) optional
- [ ] App description under 4000 characters
- [ ] Feature graphic (1024x500 px)
- [ ] App icon 512x512 px (already configured)

## 🔒 Security Notes

- **Never commit** `android/key.properties` or `.jks` to public repositories
- `.gitignore` already includes `key.properties` and `*.jks`
- Store the `.jks` file securely (backup to encrypted drive)
- Keep passwords safe—they cannot be recovered if lost
- For CI/CD, use environment variables instead of plaintext passwords

## 🎯 Key File Locations

- Signing config: `android/app/build.gradle.kts`
- Key properties: `android/key.properties`
- Keystore: `android/app/smartgatebd.jks` (after generation)
- Release bundle: `build/app/outputs/bundle/release/app-release.aab`

## 📞 Troubleshooting

### "Keystore file not found"
→ Generate keystore first (Step 1)

### "Gradle build failed"
→ Run `flutter clean && flutter pub get`

### "Version code must be greater than X"
→ Increment `versionCode` in pubspec.yaml (second number in version string)

### "APK rejected by Play Store for target SDK"
→ Ensure `targetSdk` in build.gradle.kts is current (API 35+)

## Next Steps

1. ✅ This configuration is **production-ready**
2. Generate the keystore (Step 1)
3. Build the AAB (Step 2)
4. Upload to Play Store (Step 3)
5. Publish and celebrate! 🎉
