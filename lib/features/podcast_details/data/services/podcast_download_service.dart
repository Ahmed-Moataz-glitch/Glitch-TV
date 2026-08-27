import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:glitch_tv/features/downloads/data/models/downloaded_episode_dto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PodcastDownloadService {
  static final PodcastDownloadService _instance =
      PodcastDownloadService._internal();
  factory PodcastDownloadService() => _instance;
  PodcastDownloadService._internal();

  static const String _boxName = 'downloaded_podcasts_box';

  static const MethodChannel _mediaScannerChannel =
      MethodChannel('com.example.glitch_tv/media_scanner');

  final Map<String, double> _activeDownloads = {};
  final Map<String, StreamController<double>> _progressControllers = {};

  Future<Box<dynamic>?> _getBox() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        return Hive.box<dynamic>(_boxName);
      }
      return await Hive.openBox<dynamic>(_boxName);
    } catch (e) {
      debugPrint('Hive box open error in PodcastDownloadService: $e');
      return null;
    }
  }

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
    final key = _generateKey(podcastId, audioUrl);
    final fileName = sanitizeFileName(episodeTitle, audioUrl);

    // 1. Check Hive record for direct local path
    try {
      final box = await _getBox();
      final raw = box?.get(key);
      if (raw != null) {
        final Map<String, dynamic> map = raw is String
            ? jsonDecode(raw) as Map<String, dynamic>
            : Map<String, dynamic>.from(raw as Map);
        final localPath = map['localPath'] as String?;
        if (localPath != null && localPath.isNotEmpty) {
          final file = File(localPath);
          if (await file.exists() && await file.length() > 0) {
            return file;
          }
        }
      }
    } catch (_) {}

    // 2. Check candidate paths in application and external storage
    final candidatePaths = <String>[];
    String? appDirPath;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      appDirPath = appDir.path;
      candidatePaths.add('${appDir.path}/Podcasts/$fileName');
      candidatePaths.add('${appDir.path}/podcast_downloads/$fileName');
    } catch (_) {}

    if (Platform.isAndroid) {
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          candidatePaths.add('${ext.path}/Podcasts/$fileName');
        }
      } catch (_) {}
      candidatePaths.add('/storage/emulated/0/Podcasts/$fileName');
    }

    for (final path in candidatePaths) {
      try {
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          // If the file is in public storage and not in app internal storage, copy to app storage for guaranteed ExoPlayer read access on Android 10+
          if (appDirPath != null && !path.startsWith(appDirPath)) {
            final localFile = File('$appDirPath/Podcasts/$fileName');
            if (!await localFile.exists()) {
              await localFile.parent.create(recursive: true);
              await file.copy(localFile.path);
              return localFile;
            }
          }
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
    String podcastName = '',
    String podcastHost = '',
    String podcastArtwork = '',
    String duration = '',
    String pubDate = '',
    Function(double progress)? onProgress,
  }) async {
    final key = _generateKey(podcastId, audioUrl);
    final fileName = sanitizeFileName(episodeTitle, audioUrl);

    // Target Podcasts directory
    final appDir = await getApplicationDocumentsDirectory();
    final podcastsDir = Directory('${appDir.path}/Podcasts');
    if (!await podcastsDir.exists()) {
      await podcastsDir.create(recursive: true);
    }

    final targetFile = File('${podcastsDir.path}/$fileName');
    final partFile = File('${podcastsDir.path}/$fileName.download');

    final controller = StreamController<double>.broadcast();
    _progressControllers[key] = controller;
    _activeDownloads[key] = 0.0;

    final client = http.Client();
    try {
      if (await partFile.exists()) {
        await partFile.delete();
      }

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

      final sink = partFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          _activeDownloads[key] = progress;
          controller.add(progress);
          onProgress?.call(progress);
        }
      }

      await sink.flush();
      await sink.close();

      // Rename .download file to final target file in Podcasts directory
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await partFile.rename(targetFile.path);

      // On Android, ALSO export/save to Public Podcasts folder via MediaStore so system media scanner detects it
      if (Platform.isAndroid) {
        try {
          await _mediaScannerChannel.invokeMethod('saveToPodcasts', {
            'tempPath': targetFile.path,
            'fileName': fileName,
          });
        } catch (e) {
          debugPrint('MediaStore export error (non-fatal): $e');
        }
      }

      // Save metadata to Hive
      try {
        final fileLength = await targetFile.length();
        final sizeStr = formatBytes(fileLength);
        final dto = DownloadedEpisodeDto(
          id: key,
          podcastId: podcastId,
          podcastName: podcastName,
          episodeTitle: episodeTitle,
          audioUrl: audioUrl,
          localPath: targetFile.path,
          artworkUrl: podcastArtwork,
          host: podcastHost,
          duration: duration,
          pubDate: pubDate,
          fileSize: sizeStr,
          downloadedAt: DateTime.now(),
        );
        await saveDownloadedEpisodeRecord(dto);
      } catch (e) {
        debugPrint('Error saving download record to Hive: $e');
      }

      _activeDownloads[key] = 1.0;
      controller.add(1.0);
      onProgress?.call(1.0);

      return targetFile;
    } catch (e) {
      if (await partFile.exists()) {
        try {
          await partFile.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      client.close();
      _activeDownloads.remove(key);
      await controller.close();
      _progressControllers.remove(key);
    }
  }

  Future<void> saveDownloadedEpisodeRecord(DownloadedEpisodeDto dto) async {
    final box = await _getBox();
    if (box == null) return;
    final jsonStr = jsonEncode(dto.toJson());
    await box.put(dto.id, jsonStr);
  }

  Future<void> removeDownloadedEpisodeRecord(
    String podcastId,
    String audioUrl,
  ) async {
    final box = await _getBox();
    if (box == null) return;
    final key = _generateKey(podcastId, audioUrl);
    await box.delete(key);
  }

  Future<List<DownloadedEpisodeDto>> getDownloadedEpisodes() async {
    final box = await _getBox();
    final List<DownloadedEpisodeDto> episodes = [];
    final Set<String> seenPaths = {};
    final Set<String> seenTitles = {};

    // 1. Load from Hive
    if (box != null) {
      final List<dynamic> keysToDelete = [];
      for (var key in box.keys) {
        final value = box.get(key);
        if (value != null) {
          try {
            DownloadedEpisodeDto dto;
            if (value is String) {
              final map = jsonDecode(value) as Map<String, dynamic>;
              dto = DownloadedEpisodeDto.fromJson(map);
            } else if (value is Map) {
              final map = Map<String, dynamic>.from(value);
              dto = DownloadedEpisodeDto.fromJson(map);
            } else {
              continue;
            }

            // Verify if file still exists on disk
            final file = await getDownloadedFile(
              podcastId: dto.podcastId,
              episodeTitle: dto.episodeTitle,
              audioUrl: dto.audioUrl,
            );

            if (file != null && await file.exists() && await file.length() > 0) {
              final length = await file.length();
              dto = dto.copyWith(
                localPath: file.path,
                fileSize: formatBytes(length),
              );
              episodes.add(dto);
              seenPaths.add(file.path);
              seenTitles.add(dto.episodeTitle.trim().toLowerCase());
            } else {
              keysToDelete.add(key);
            }
          } catch (e) {
            debugPrint('Error parsing downloaded episode dto: $e');
          }
        }
      }

      // Clean up orphaned records
      for (var k in keysToDelete) {
        await box.delete(k);
      }
    }

    // 2. Scan physical Podcasts directories for all downloaded episodes on device
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dirsToScan = <Directory>[
        Directory('${appDir.path}/Podcasts'),
        Directory('${appDir.path}/podcast_downloads'),
      ];

      if (Platform.isAndroid) {
        try {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            dirsToScan.add(Directory('${ext.path}/Podcasts'));
          }
        } catch (_) {}
        dirsToScan.add(Directory('/storage/emulated/0/Podcasts'));
      }

      final audioExtensions = {'.mp3', '.m4a', '.aac', '.wav', '.ogg'};

      for (final dir in dirsToScan) {
        if (!await dir.exists()) continue;
        try {
          final entities = await dir.list().toList();
          for (final entity in entities) {
            if (entity is! File) continue;

            final path = entity.path;
            final fileName = path.split(Platform.pathSeparator).last;
            if (fileName.endsWith('.download') || fileName.endsWith('.tmp')) {
              continue;
            }

            final dotIndex = fileName.lastIndexOf('.');
            if (dotIndex == -1) continue;

            final ext = fileName.substring(dotIndex).toLowerCase();
            if (!audioExtensions.contains(ext)) continue;

            final length = await entity.length();
            if (length == 0) continue;

            final title = fileName.substring(0, dotIndex).trim();
            final titleNorm = title.toLowerCase();

            if (seenTitles.contains(titleNorm) || seenPaths.contains(path)) {
              continue;
            }

            // Ensure file is accessible in app storage for ExoPlayer on Android 10+
            File playbackFile = entity;
            if (!path.startsWith(appDir.path)) {
              final localFile = File('${appDir.path}/Podcasts/$fileName');
              if (!await localFile.exists()) {
                await localFile.parent.create(recursive: true);
                await entity.copy(localFile.path);
              }
              playbackFile = localFile;
            }

            final lastModified = await entity.lastModified();
            final dto = DownloadedEpisodeDto(
              id: 'file_${playbackFile.path.hashCode.abs()}',
              podcastId: 'local_podcasts',
              podcastName: 'Podcasts',
              episodeTitle: title,
              audioUrl: playbackFile.path,
              localPath: playbackFile.path,
              artworkUrl: '',
              host: '',
              duration: '',
              pubDate: '',
              fileSize: formatBytes(length),
              downloadedAt: lastModified,
            );

            episodes.add(dto);
            seenPaths.add(playbackFile.path);
            seenTitles.add(titleNorm);

            // Persist discovered file metadata into Hive
            if (box != null) {
              await saveDownloadedEpisodeRecord(dto);
            }
          }
        } catch (e) {
          debugPrint('Error scanning dir ${dir.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error scanning podcast directories: $e');
    }

    episodes.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return episodes;
  }

  Future<int> getTotalDownloadedSizeBytes() async {
    final episodes = await getDownloadedEpisodes();
    int total = 0;
    for (var ep in episodes) {
      final size = await getDownloadedFileSize(
        podcastId: ep.podcastId,
        episodeTitle: ep.episodeTitle,
        audioUrl: ep.audioUrl,
      );
      total += size;
    }
    return total;
  }

  Future<String> getTotalDownloadedSizeFormatted() async {
    final total = await getTotalDownloadedSizeBytes();
    return formatBytes(total);
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

    await removeDownloadedEpisodeRecord(podcastId, audioUrl);

    return deleted;
  }
}
