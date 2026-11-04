# Installation Guide

## Download
Get the latest APK from the [Releases page](https://github.com/JustCodebyHK/ERP/releases).

## Install on Android

### Step 1: Enable Unknown Sources
1. Go to **Settings** > **Security** (or **Apps** > **Special app access**)
2. Enable **Install from unknown sources** for your browser or file manager
3. On Android 8+: Allow your browser to install unknown apps

### Step 2: Download the APK
Download `app-release.apk` to your device.

### Step 3: Install
1. Open your file manager and navigate to the Downloads folder
2. Tap on `app-release.apk`
3. Tap **Install**
4. Wait for installation to complete
5. Tap **Done** or **Open**

## Verify Integrity
Before installing, verify the APK checksum:

```bash
sha256sum app-release.apk
# Expected: D7986F35FFE57407A91A2403693C6BE6FA5827BC1B592CAB03F56C3BC74EE07D
```

## Uninstall Previous Version
If upgrading from a previous version, uninstall the old app first:
```bash
adb uninstall com.studentacademic.student_academic_app
```