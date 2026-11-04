# APK Signing Information

## Release APK
The `app-release.apk` is signed with the application's release keystore for distribution on the Google Play Store and direct installation.

## Debug APK
The `app-debug.apk` is signed with the Android SDK debug keystore for development and testing purposes only. Do not distribute debug APKs to end users.

## Signature Verification
Verify the APK signature before installation:

```bash
apksigner verify app-release.apk
```

## Keystore
The release keystore is stored securely and is not included in this repository. To rebuild the release APK:

1. Generate a new keystore:
   ```bash
   keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release-key
   ```

2. Add signing config to `android/app/build.gradle.kts`:
   ```kotlin
   signingConfigs {
       release {
           storeFile(file("release-key.jks"))
           storePassword(System.getenv("STORE_PASSWORD"))
           keyAlias("release-key")
           keyPassword(System.getenv("KEY_PASSWORD"))
       }
   }
   ```

3. Build release APK:
   ```bash
   flutter build apk --release
   ```