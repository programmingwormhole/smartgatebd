# 🔑 Manual Keystore Generation Guide

Since Java isn't installed on this machine, follow these steps to install Java and generate your keystore:

## Option A: Install via Homebrew (Recommended for Mac)

Open Terminal and run:

```bash
brew install temurin@21
```

This will prompt for your sudo password. Enter it to complete the installation.

Once installed, verify Java is working:
```bash
java -version
```

## Option B: Download Directly

If Homebrew installation fails, download Java from:
**https://adoptium.net/temurin/**

Choose:
- **Version:** 21 LTS (or 17 LTS)
- **OS:** macOS
- **Architecture:** Arm 64 (for Apple Silicon M1/M2/M3) or x86 64 (for Intel)

Download the `.dmg` file and install by double-clicking it.

## Step 1: Generate Keystore

After Java is installed, run this command in Terminal from the project directory:

```bash
cd /Volumes/Project/Client\ Project/SmartGateBD/society_user

keytool -genkeypair -v -keystore android/app/smartgatebd.jks \
  -alias smartgatebd \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass smartgatebd \
  -keypass smartgatebd \
  -dname "CN=SmartGateBD, OU=SmartGateBD, O=SmartGateBD, L=Dhaka, S=Dhaka, C=BD"
```

Expected output:
```
Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA)...
```

Verify the file was created:
```bash
ls -lh android/app/smartgatebd.jks
```

You should see the `.jks` file listed.

## Step 2: Build Release Bundle

```bash
cd /Volumes/Project/Client\ Project/SmartGateBD/society_user

flutter clean
flutter pub get
flutter build appbundle --release
```

This will take 3-5 minutes. The output will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Step 3: Upload to Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Select **SmartGateBD - User** app
3. Click **Release** → **Production**
4. Click **Create new release**
5. Upload the AAB file from `build/app/outputs/bundle/release/app-release.aab`
6. Fill in release notes
7. Review and publish

---

## 🔐 Security Checklist

Before publishing:

- [ ] Version in `pubspec.yaml` is incremented
- [ ] All test runs pass
- [ ] No debug logs in production code
- [ ] `key.properties` is in `.gitignore` (already done)
- [ ] `.jks` file is backed up securely
- [ ] Privacy policy link is ready

---

## ⚠️ Important Notes

1. **Keystore password:** Keep `smartgatebd` safe. If lost, you cannot sign app updates.
2. **Never commit:** Don't upload `android/key.properties` or `.jks` to GitHub
3. **Version code:** Each Play Store upload must have a higher `versionCode` (number after `+` in version)
4. **One keystore per app:** Use the same `.jks` for all future updates to this app

---

## Run Automated Build (After Java Install)

Once Java is installed, you can use the automated script:

```bash
cd /Volumes/Project/Client\ Project/SmartGateBD/society_user
bash build_release.sh
```

This will handle Java check, keystore generation, and release build all in one command.

---

Still stuck? Check:
- `java -version` returns a version (not "Unable to locate")
- You're in the correct directory (`society_user`)
- `keytool` is accessible (usually auto-installed with Java)
