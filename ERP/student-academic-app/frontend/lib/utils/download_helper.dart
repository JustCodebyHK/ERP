import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of the storage permission flow.
class StoragePermissionResult {
  /// True when the app can write files to the public Downloads folder.
  final bool granted;

  /// True when we sent the user to the system settings page but the
  /// permission was still not enabled when they came back.
  final bool needsSettings;

  const StoragePermissionResult(this.granted, {this.needsSettings = false});
}

/// Makes sure the app is allowed to save files into the public Downloads
/// folder.
///
/// * Android 11+ requires the special "All files access" permission
///   (MANAGE_EXTERNAL_STORAGE). There is no system popup for it - the user
///   must flip a switch on a settings page, so we explain that first.
/// * Android 10 and below use the classic storage permission dialog.
Future<StoragePermissionResult> ensureStoragePermission(
    BuildContext context) async {
  if (!Platform.isAndroid) return const StoragePermissionResult(true);

  final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

  if (sdkInt >= 30) {
    // Android 11+ : "All files access"
    if (await Permission.manageExternalStorage.isGranted) {
      return const StoragePermissionResult(true);
    }

    if (!context.mounted) return const StoragePermissionResult(false);

    final goToSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Allow File Access'),
        content: const Text(
            'To save downloaded files to the Downloads folder so you can '
            'open them with other apps, this app needs the "All files '
            'access" permission.\n\n'
            'Tap "Open Settings", turn on "Allow management of all files", '
            'then come back to the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (goToSettings != true) {
      return const StoragePermissionResult(false);
    }

    // Opens the "All files access" settings page for this app.
    await Permission.manageExternalStorage.request();
    final granted = await Permission.manageExternalStorage.isGranted;
    return StoragePermissionResult(granted, needsSettings: !granted);
  }

  // Android 10 and below : classic storage permission (shows a dialog).
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }
  return StoragePermissionResult(status.isGranted);
}

/// Returns a directory where downloaded files should be stored.
///
/// On Android this is `<public Downloads>/<subfolder>` so the files are
/// visible in any file manager and can be opened by other apps. When the
/// public folder cannot be used (e.g. permission was not granted) it falls
/// back to the app-specific external directory, then to app documents.
Future<Directory> resolveDownloadDirectory(String subfolder) async {
  if (Platform.isAndroid) {
    final publicRoot = Directory('/storage/emulated/0/Download');
    if (await publicRoot.exists()) {
      final target = subfolder.isEmpty
          ? publicRoot
          : Directory('${publicRoot.path}${Platform.pathSeparator}$subfolder');
      try {
        if (!await target.exists()) {
          await target.create(recursive: true);
        }
        return target;
      } on FileSystemException {
        // No access to the public folder - fall through to app storage.
      }
    }

    final ext = await getExternalStorageDirectory();
    if (ext != null) {
      final target = subfolder.isEmpty
          ? ext
          : Directory('${ext.path}${Platform.pathSeparator}$subfolder');
      if (!await target.exists()) await target.create(recursive: true);
      return target;
    }
  }

  final docs = await getApplicationDocumentsDirectory();
  if (subfolder.isEmpty) return docs;
  final target =
      Directory('${docs.path}${Platform.pathSeparator}$subfolder');
  if (!await target.exists()) await target.create(recursive: true);
  return target;
}
