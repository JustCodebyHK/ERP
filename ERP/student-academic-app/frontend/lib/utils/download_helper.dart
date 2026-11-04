import 'dart:io';

class DownloadHelper {
  static final DownloadHelper _instance = DownloadHelper._internal();
  factory DownloadHelper() => _instance;
  DownloadHelper._internal();

  int _maxRetries = 3;
  Duration _retryDelay = const Duration(seconds: 2);

  void setMaxRetries(int retries) {
    _maxRetries = retries;
  }

  void setRetryDelay(Duration delay) {
    _retryDelay = delay;
  }

  Future<bool> downloadFile(String url, String savePath,
      {int? maxRetries}) async {
    final retries = maxRetries ?? _maxRetries;
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode == 200) {
          final file = File(savePath);
          await response.pipe(file.openWrite());
          return true;
        }
      } catch (_) {
        if (attempt < retries - 1) {
          await Future.delayed(_retryDelay);
        }
      }
    }
    return false;
  }

  int get maxRetries => _maxRetries;
  Duration get retryDelay => _retryDelay;
}
