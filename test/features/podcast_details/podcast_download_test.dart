import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glitch_tv/features/podcast_details/data/services/podcast_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late PodcastDownloadService service;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('podcast_test_');

    const MethodChannel pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel,
            (MethodCall methodCall) async {
      return tempDir.path;
    });

    const MethodChannel mediaScannerChannel =
        MethodChannel('com.example.glitch_tv/media_scanner');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mediaScannerChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'saveToPodcasts') {
        final fileName = methodCall.arguments['fileName'] as String;
        return '${tempDir.path}/Podcasts/$fileName';
      }
      if (methodCall.method == 'deleteFromPodcasts') {
        return true;
      }
      return null;
    });

    service = PodcastDownloadService();
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PodcastDownloadService Tests', () {
    const testPodcastId = 'el-podcast-1';
    const testEpisodeTitle = 'الحلقة الأولى من البودكاست';
    const testAudioUrl = 'https://example.com/audio/episode1.mp3';

    test('should format byte sizes correctly', () {
      expect(service.formatBytes(0), '0 B');
      expect(service.formatBytes(512), '512.0 B');
      expect(service.formatBytes(1024 * 1024 * 5), '5.0 MB');
      expect(service.formatBytes(1024 * 1024 * 1024 * 2), '2.0 GB');
    });

    test('should sanitize file name using episode title', () {
      final sanitized = service.sanitizeFileName(
          'الحلقة/1: الأسرار * الخفية?', testAudioUrl);
      expect(sanitized, 'الحلقة 1 الأسرار الخفية.mp3');
    });

    test('should return valid file paths inside Podcasts folder with episode title',
        () async {
      final path = await service.getDownloadPath(
        podcastId: testPodcastId,
        episodeTitle: testEpisodeTitle,
        audioUrl: testAudioUrl,
      );
      expect(path.contains('Podcasts'), isTrue);
      expect(path.endsWith('الحلقة الأولى من البودكاست.mp3'), isTrue);
    });

    test('should check downloaded status, size, and deletion accurately',
        () async {
      expect(
        await service.isEpisodeDownloaded(
          podcastId: testPodcastId,
          episodeTitle: testEpisodeTitle,
          audioUrl: testAudioUrl,
        ),
        isFalse,
      );

      final fileName =
          service.sanitizeFileName(testEpisodeTitle, testAudioUrl);
      final podcastsDir = Directory('${tempDir.path}/Podcasts');
      if (!podcastsDir.existsSync()) {
        podcastsDir.createSync(recursive: true);
      }
      final file = File('${podcastsDir.path}/$fileName');
      await file.writeAsString('sample podcast mp3 binary data');

      expect(
        await service.isEpisodeDownloaded(
          podcastId: testPodcastId,
          episodeTitle: testEpisodeTitle,
          audioUrl: testAudioUrl,
        ),
        isTrue,
      );

      final size = await service.getDownloadedFileSize(
        podcastId: testPodcastId,
        episodeTitle: testEpisodeTitle,
        audioUrl: testAudioUrl,
      );
      expect(size > 0, isTrue);

      final deleted = await service.deleteDownloadedEpisode(
        podcastId: testPodcastId,
        episodeTitle: testEpisodeTitle,
        audioUrl: testAudioUrl,
      );
      expect(deleted, isTrue);
      expect(
        await service.isEpisodeDownloaded(
          podcastId: testPodcastId,
          episodeTitle: testEpisodeTitle,
          audioUrl: testAudioUrl,
        ),
        isFalse,
      );
    });
  });
}
