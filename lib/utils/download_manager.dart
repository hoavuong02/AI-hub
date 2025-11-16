import 'dart:io';
import 'package:aihub/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_notifications/awesome_notifications.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  Future<void> downloadFile(
    BuildContext context,
    String url,
    String fileName, {
    bool showNotification = true,
  }) async {
    if (url.contains("blob:")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot download file with blob URL'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red.shade500,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    _showEnhancedSnackBar(fileName, context);
    if (showNotification) {
      await _setupAllChannels();
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'downloads_progress',
          title: '📥 Preparing Download',
          body: 'Getting ready to download "$fileName"',
          color: Colors.blue.shade700,
          backgroundColor: Colors.blue.shade50,
          notificationLayout: NotificationLayout.ProgressBar,
          progress: 0,
          locked: true,
          autoDismissible: false,
          payload: {'action': 'preparing', 'fileName': fileName},
        ),
      );
    }

    try {
      final downloadsDir = await _getDownloadDirectory();
      final savePath = '${downloadsDir.path}/$fileName';
      File file = File(savePath);

      if (await file.exists()) {
        file = await _handleDuplicateFile(downloadsDir, fileName);
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers.putIfAbsent("User-Agent", () => userAgent);
      request.headers.putIfAbsent("Accept", () => "*/*");
      request.headers.putIfAbsent("Connection", () => "keep-alive");

      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final stopwatch = Stopwatch()..start();
      int lastUpdateTime = 0;

      final raf = file.openSync(mode: FileMode.write);

      try {
        await for (final chunk in response.stream) {
          receivedBytes += chunk.length;
          raf.writeFromSync(chunk);

          final currentTime = DateTime.now().millisecondsSinceEpoch;
          if (showNotification && currentTime - lastUpdateTime > 200) {
            lastUpdateTime = currentTime;
            final progress = totalBytes > 0
                ? (receivedBytes / totalBytes * 100).round()
                : 0;
            final downloadSpeed = _calculateSpeed(
              receivedBytes,
              stopwatch.elapsedMilliseconds,
            );
            final estimatedTime = _calculateRemainingTime(
              receivedBytes,
              totalBytes,
              downloadSpeed,
            );

            await _updateProgressNotification(
              notificationId: notificationId,
              fileName: fileName,
              progress: progress,
              receivedBytes: receivedBytes,
              totalBytes: totalBytes,
              downloadSpeed: downloadSpeed,
              estimatedTime: estimatedTime,
            );
          }
        }
      } finally {
        await raf.close();
      }

      client.close();
      stopwatch.stop();

      if (showNotification) {
        await _showDownloadCompleteNotification(
          notificationId: notificationId,
          fileName: fileName,
          savePath: savePath,
          receivedBytes: receivedBytes,
        );
      }

      debugPrint(
        '✅ Download successful: $savePath (${_formatFileSize(receivedBytes)})',
      );
    } catch (e, stackTrace) {
      if (showNotification) {
        await _showDownloadErrorNotification(
          notificationId: notificationId,
          fileName: fileName,
          url: url,
          error: e.toString(),
        );
      }

      debugPrint('❌ Download failed: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _setupAllChannels() async {
    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: 'downloads_progress',
        channelName: 'Download Progress',
        channelDescription: 'Notifications for download progress',
        importance: NotificationImportance.Low,
        channelShowBadge: false,
        enableVibration: false,
        playSound: false,
        locked: true,
        enableLights: false,
      ),
    );

    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: 'downloads_complete',
        channelName: 'Download Complete',
        channelDescription: 'Notifications for completed downloads',
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        vibrationPattern: lowVibrationPattern,
        ledColor: Colors.green,
        locked: false,
        enableLights: true,
        playSound: true,
      ),
    );

    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: 'downloads_error',
        channelName: 'Download Error',
        channelDescription: 'Notifications for download errors',
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        vibrationPattern: lowVibrationPattern,
        ledColor: Colors.red,
        locked: false,
        enableLights: true,
        playSound: true,
      ),
    );
  }

  Future<File> _handleDuplicateFile(
    Directory downloadsDir,
    String fileName,
  ) async {
    final filePath = '${downloadsDir.path}/$fileName';
    final fileNameWithExt = filePath.split('/').last;
    final lastDotIndex = fileNameWithExt.lastIndexOf('.');

    String name;
    String? extension;

    if (lastDotIndex != -1) {
      name = fileNameWithExt.substring(0, lastDotIndex);
      extension = fileNameWithExt.substring(lastDotIndex + 1);
    } else {
      name = fileNameWithExt;
      extension = null;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = extension != null
        ? '$name ($timestamp).$extension'
        : '$name ($timestamp)';

    return File('${downloadsDir.path}/$newFileName');
  }

  Future<void> _updateProgressNotification({
    required int notificationId,
    required String fileName,
    required int progress,
    required int receivedBytes,
    required int totalBytes,
    required double downloadSpeed,
    required String estimatedTime,
  }) async {
    String progressBody;

    if (totalBytes > 0) {
      final fileSizeInfo =
          '${_formatFileSize(receivedBytes)} / ${_formatFileSize(totalBytes)}';
      final speedInfo =
          '${_formatSpeed(downloadSpeed)} • ${estimatedTime.isEmpty ? 'Calculating...' : estimatedTime}';
      progressBody = '$fileSizeInfo\n$speedInfo';
    } else {
      progressBody = '${_formatFileSize(receivedBytes)} downloaded';
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'downloads_progress',
        title: progress == 100 ? '🎉 Finalizing...' : '📥 Downloading...',
        body: progressBody,
        color: _getProgressColor(progress),
        notificationLayout: NotificationLayout.ProgressBar,
        progress: progress.toDouble(),
        locked: true,
        autoDismissible: false,
        payload: {
          'action': 'progress',
          'fileName': fileName,
          'progress': progress.toString(),
        },
      ),
      actionButtons: [],
    );
  }

  Future<void> _showDownloadCompleteNotification({
    required int notificationId,
    required String fileName,
    required String savePath,
    required int receivedBytes,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'downloads_complete',
        title: '✅ Download Complete!',
        body: '"$fileName" is ready to use',
        color: Colors.green.shade600,
        backgroundColor: Colors.green.shade50,
        notificationLayout: NotificationLayout.BigPicture,
        payload: {
          'action': 'open',
          'filePath': savePath,
          'fileName': fileName,
          'fileSize': receivedBytes.toString(),
        },
        locked: false,
        autoDismissible: true,
      ),
    );
  }

  Future<void> _showDownloadErrorNotification({
    required int notificationId,
    required String fileName,
    required String url,
    required String error,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'downloads_error',
        title: '❌ Download Failed',
        body: 'Could not download "$fileName"',
        color: Colors.red.shade600,
        backgroundColor: Colors.red.shade50,
        notificationLayout: NotificationLayout.BigText,
        payload: {
          'action': 'retry',
          'url': url,
          'fileName': fileName,
          'error': error,
        },
        locked: false,
        autoDismissible: true,
      ),
    );
  }

  Future<Directory> _getDownloadDirectory() async {
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  double _calculateSpeed(int bytes, int milliseconds) {
    if (milliseconds == 0) return 0;
    return bytes / (milliseconds / 1000);
  }

  String _calculateRemainingTime(int received, int total, double speed) {
    if (speed == 0 || total == 0) return '';

    final remainingBytes = total - received;
    final secondsRemaining = remainingBytes / speed;

    if (secondsRemaining < 60) {
      return '${secondsRemaining.round()}s';
    } else if (secondsRemaining < 3600) {
      return '${(secondsRemaining / 60).round()}m';
    } else {
      return '${(secondsRemaining / 3600).round()}h';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.round()} B/s';
    if (bytesPerSecond < 1048576) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSecond / 1048576).toStringAsFixed(1)} MB/s';
  }

  Color _getProgressColor(int progress) {
    if (progress < 30) return Colors.orange.shade600;
    if (progress < 70) return Colors.blue.shade600;
    return Colors.green.shade600;
  }

  void _showEnhancedSnackBar(String fileName, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = colorScheme.primary.withValues(alpha: 0.9);
    final onBackgroundColor = colorScheme.onPrimary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: onBackgroundColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_rounded,
                size: 20,
                color: onBackgroundColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Download Started',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: onBackgroundColor.withValues(alpha: 0.95),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 12,
                      color: onBackgroundColor.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(onBackgroundColor),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: backgroundColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
