import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PodcastDownloadService {
  static final PodcastDownloadService _instance =
      PodcastDownloadService._internal();
  factory PodcastDownloadService() => _instance;
  PodcastDownloadService._internal();

  static const MethodChannel _mediaScannerChannel =
      MethodChannel('com.example.glitch_tv/media_scanner');

  final Map<String, double> _activeDownloads = {};
  final Map<String, StreamController<double>> _progressControllers = {};

  bool isDownloading(String podcastId, String audioUrl) {
    final key = _generateKey(podcastId, audioUrl);
    return _activeDownloads.containsKey(key);
  }

  double getDownloadProgress(String podcastId, String audioUrl) {
    final key = _generateKey(podcastId, audioUrl);
    return _activeDownloads[key] ?? 0.0;
  }

  Stream<double>? getProgressStream(String podcastId, String audioUrl) {
    final key = _generateKey(podcastId, audioUrl);
    return _progressControllers[key]?.stream;
  }

  String _generateKey(String podcastId, String audioUrl) {
    return '$podcastId-$audioUrl';
  }

  String sanitizeFileName(String title, String audioUrl) {
    // Remove invalid file system characters: \ / : * ? " < > |
    var clean = title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ').trim();
    clean = clean.replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) {
      clean = 'Podcast_Episode_${audioUrl.hashCode.abs()}';
    }

    String ext = '.mp3';
    final cleanUrl = audioUrl.split('?').first.toLowerCase();
    if (cleanUrl.endsWith('.m4a')) {
      ext = '.m4a';
    } else if (cleanUrl.endsWith('.aac')) {
      ext = '.aac';
    } else if (cleanUrl.endsWith('.wav')) {
      ext = '.wav';
    } else if (cleanUrl.endsWith('.ogg')) {
      ext = '.ogg';
    }

    return '$clean$ext';
  }

  Future<String> getDownloadPath({
    required String podcastId,
    required String episodeTitle,
    required String audioUrl,
  }) async {
    final fileName = sanitizeFileName(episodeTitle, audioUrl);
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Podcasts/$fileName';
    }
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/Podcasts/$fileName';
  }

  Future<File?> getDownloadedFile({
    required String podcastId,
    required String episodeTitle,
    required String audioUrl,
  }) async {
    final fileName = sanitizeFileName(episodeTitle, audioUrl);
    final candidatePaths = <String>[];

    if (Platform.isAndroid) {
      candidatePaths.add('/storage/emulated/0/Podcasts/$fileName');
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          candidatePaths.add('${ext.path}/Podcasts/$fileName');
        }
      } catch (_) {}
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      candidatePaths.add('${appDir.path}/Podcasts/$fileName');
      candidatePaths.add('${appDir.path}/podcast_downloads/$fileName');
    } catch (_) {}

    for (final path in candidatePaths) {
      try {
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          return file;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<bool> isEpisodeDownloaded({
    required String podcastId,
    required String episodeTitle,
    required String audioUrl,
  }) async {
    try {
      final file = await getDownloadedFile(
        podcastId: podcastId,
        episodeTitle: episodeTitle,
        audioUrl: audioUrl,
      );
      return file != null;
    } catch (_) {
      return false;
    }
  }

  Future<int> getDownloadedFileSize({
    required String podcastId,
    required String episodeTitle,
    required String audioUrl,
  }) async {
    try {
      final file = await getDownloadedFile(
        podcastId: podcastId,
        episodeTitle: episodeTitle,
        audioUrl: audioUrl,
      );
      if (file != null) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<File> downloadEpisode({
    required String podcastId,
    required String episodeTitle,
    required String audioUrl,
    Function(double progress)? onProgress,
  }) async {
    final key = _generateKey(podcastId, audioUrl);
    final fileName = sanitizeFileName(episodeTitle, audioUrl);

    final tempDir = await getTemporaryDirectory();
    final tempPath =
        '${tempDir.path}/download_${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final controller = StreamController<double>.broadcast();
    _progressControllers[key] = controller;
    _activeDownloads[key] = 0.0;

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(audioUrl));
      request.headers.addAll({
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
      });

      final response = await client.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
            'Download failed with status: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      final sink = tempFile.openWrite();

      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
            _activeDownloads[key] = progress;
            controller.add(progress);
            onProgress?.call(progress);
          }
        },
        cancelOnError: true,
      ).asFuture();

      await sink.flush();
      await sink.close();

      File? resultFile;

      // 1. Save to Public Android Podcasts folder via MediaStore
      if (Platform.isAndroid) {
        try {
          final String? savedPath =
              await _mediaScannerChannel.invokeMethod('saveToPodcasts', {
            'tempPath': tempFile.path,
            'fileName': fileName,
          });
          if (savedPath != null && savedPath.isNotEmpty) {
            final saved = File(savedPath);
            if (await saved.exists()) {
              resultFile = saved;
            }
          }
        } catch (e) {
          debugPrint('MediaStore saveToPodcasts platform error: $e');
        }
      }

      // 2. Fallback to app directory if platform method channel failed or on other OS
      if (resultFile == null) {
        final appDir = await getApplicationDocumentsDirectory();
        final localDir = Directory('${appDir.path}/Podcasts');
        if (!await localDir.exists()) {
          await localDir.create(recursive: true);
        }
        final targetFile = File('${localDir.path}/$fileName');
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tempFile.copy(targetFile.path);
        resultFile = targetFile;
      }

      _activeDownloads[key] = 1.0;
      controller.add(1.0);
      onProgress?.call(1.0);

      return resultFile;
    } catch (e) {
      rethrow;
    } finally {
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      client.close();
      _activeDownloads.remove(key);
      await controller.close();
      _progressControllers.remove(key);
    }
  }

  Future<bool> deleteDownloadedEpisode({
    required String podcastId,
    required String episodeTitle,
    required String audioUrl,
  }) async {
    final fileName = sanitizeFileName(episodeTitle, audioUrl);
    var deleted = false;

    if (Platform.isAndroid) {
      try {
        final bool? res =
            await _mediaScannerChannel.invokeMethod('deleteFromPodcasts', {
          'fileName': fileName,
        });
        if (res == true) {
          deleted = true;
        }
      } catch (e) {
        debugPrint('MediaStore deleteFromPodcasts error: $e');
      }
    }

    final file = await getDownloadedFile(
      podcastId: podcastId,
      episodeTitle: episodeTitle,
      audioUrl: audioUrl,
    );
    if (file != null && await file.exists()) {
      try {
        await file.delete();
        deleted = true;
      } catch (e) {
        debugPrint('Error deleting downloaded file: $e');
      }
    }
    return deleted;
  }
}
