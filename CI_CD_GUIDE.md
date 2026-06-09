# D&D Catalog App CI/CD Guide

This repository has a GitHub Actions workflow configured in `.github/workflows/build.yml` that builds the application for Android and iOS on every push to the `main` branch.

To keep the pipeline generic, it is currently configured to build:
1. **Android:** Unsigned/debug-signed release APK and AAB.
2. **iOS:** Unsigned Release build (`--no-codesign`).

Below are instructions on how to configure full code signing for both platforms so that you can publish directly to the Google Play Store and Apple App Store.

---

## 🔑 Android Code Signing Setup

To generate a release APK/AAB signed with your upload key:

1. **Generate a Keystore:**
   If you don't have one, generate a keystore file using the `keytool` command:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Encode the Keystore to Base64:**
   Encode your `.jks` file to a Base64 string so it can be stored as a GitHub secret:
   * **macOS/Linux:** `base64 -i upload-keystore.jks`
   * **Windows (PowerShell):** `[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))`

3. **Configure GitHub Secrets:**
   In your GitHub repository, go to **Settings > Secrets and variables > Actions** and add the following secrets:
   * `ANDROID_KEYSTORE_BASE64` - The Base64 string generated in step 2.
   * `ANDROID_KEYSTORE_PASSWORD` - The keystore password.
   * `ANDROID_KEY_ALIAS` - The key alias (e.g., `upload`).
   * `ANDROID_KEY_PASSWORD` - The key password.

4. **Update `build.gradle.kts` (or `build.gradle`):**
   Modify `dnd_wiki/android/app/build.gradle.kts` to read these properties from environment variables during the build:
   ```kotlin
   val keystoreFile = file("upload-keystore.jks")
   if (System.getenv("ANDROID_KEYSTORE_BASE64") != null) {
       val keystoreBytes = android.util.Base64.decode(System.getenv("ANDROID_KEYSTORE_BASE64"), android.util.Base64.DEFAULT)
       keystoreFile.writeBytes(keystoreBytes)
   }
   ```

---

## 🍎 iOS Code Signing Setup

iOS applications require an Apple Developer account, an iOS Distribution Certificate, and a Provisioning Profile to be signed.

1. **Obtain Apple Developer Credentials:**
   * **Distribution Certificate:** Export your Distribution Certificate from Xcode or developer.apple.com as a `.p12` file (with a password).
   * **Provisioning Profile:** Download your App Store or Ad-Hoc Provisioning Profile (`.mobileprovision`) from the Apple Developer portal.

2. **Encode files to Base64:**
   Convert both the `.p12` file and the `.mobileprovision` file to Base64.

3. **Configure GitHub Secrets:**
   Add these secrets to your repository:
   * `IOS_CERTIFICATE_BASE64` - Base64 encoded `.p12` certificate.
   * `IOS_CERTIFICATE_PASSWORD` - The password used when exporting the `.p12` certificate.
   * `IOS_PROVISION_PROFILE_BASE64` - Base64 encoded `.mobileprovision` file.
   * `IOS_KEYCHAIN_PASSWORD` - Any strong password (used to create a temporary keychain on the runner).

4. **Incorporate Signing in `build.yml`:**
   Replace the `build-ios` job with a version that installs the certificates:
   ```yaml
      - name: Install Apple Certificate and Provisioning Profile
        run: |
          # Create temporary keychain
          security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security set-keychain-settings -t 3600 -u build.keychain

          # Import certificate
          echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
          security import certificate.p12 -k build.keychain -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" build.keychain

          # Install provisioning profile
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "$PROVISION_PROFILE_BASE64" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision
        env:
          CERTIFICATE_BASE64: ${{ secrets.IOS_CERTIFICATE_BASE64 }}
          CERTIFICATE_PASSWORD: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}
          PROVISION_PROFILE_BASE64: ${{ secrets.IOS_PROVISION_PROFILE_BASE64 }}
          KEYCHAIN_PASSWORD: ${{ secrets.IOS_KEYCHAIN_PASSWORD }}
   ```
   Then replace `flutter build ios --release --no-codesign` with:
   ```yaml
   run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
   ```
