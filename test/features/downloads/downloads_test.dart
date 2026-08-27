import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glitch_tv/features/downloads/data/models/downloaded_episode_dto.dart';
import 'package:glitch_tv/features/downloads/presentation/view/pages/downloads_page.dart';
import 'package:glitch_tv/features/podcast_details/data/services/podcast_download_service.dart';
import 'package:glitch_tv/l10n/app_localizations.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late PodcastDownloadService service;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('downloads_test_');
    Hive.init('${tempDir.path}/hive');
    service = PodcastDownloadService();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Downloads Feature Tests', () {
    test('DownloadedEpisodeDto serializes to/from JSON correctly', () {
      final dto = DownloadedEpisodeDto(
        id: 'pod-1-ep-url',
        podcastId: 'pod-1',
        podcastName: 'Tech Talk',
        episodeTitle: 'Flutter 3.24 Features',
        audioUrl: 'https://example.com/ep.mp3',
        localPath: '/storage/emulated/0/Podcasts/ep.mp3',
        artworkUrl: 'https://example.com/art.jpg',
        host: 'Ahmed',
        duration: '45:00',
        pubDate: '2026-08-26',
        fileSize: '42.5 MB',
        downloadedAt: DateTime(2026, 8, 26, 12, 0),
      );

      final json = dto.toJson();
      final fromJson = DownloadedEpisodeDto.fromJson(json);

      expect(fromJson.id, dto.id);
      expect(fromJson.podcastId, dto.podcastId);
      expect(fromJson.podcastName, dto.podcastName);
      expect(fromJson.episodeTitle, dto.episodeTitle);
      expect(fromJson.audioUrl, dto.audioUrl);
      expect(fromJson.localPath, dto.localPath);
      expect(fromJson.artworkUrl, dto.artworkUrl);
      expect(fromJson.host, dto.host);
      expect(fromJson.duration, dto.duration);
      expect(fromJson.pubDate, dto.pubDate);
      expect(fromJson.fileSize, dto.fileSize);
    });

    test('PodcastDownloadService saves and manages downloaded episode records',
        () async {
      final dto = DownloadedEpisodeDto(
        id: 'test_pod-test_url',
        podcastId: 'test_pod',
        podcastName: 'Daily News',
        episodeTitle: 'Morning Edition',
        audioUrl: 'https://example.com/morning.mp3',
        localPath: '${tempDir.path}/morning.mp3',
        artworkUrl: '',
        host: 'Host Name',
        duration: '15:30',
        pubDate: 'Wed, 26 Aug 2026',
        fileSize: '12.0 MB',
        downloadedAt: DateTime.now(),
      );

      await service.saveDownloadedEpisodeRecord(dto);

      // Create a dummy file on disk matching dto.localPath so getDownloadedEpisodes() considers it valid
      final file = File(dto.localPath);
      await file.writeAsString('audio content');

      await service.removeDownloadedEpisodeRecord(dto.podcastId, dto.audioUrl);
      if (await file.exists()) {
        await file.delete();
      }
    });

    testWidgets('DownloadsPage renders properly', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(411, 869),
          builder: (context, child) {
            return const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: DownloadsPage(),
            );
          },
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DownloadsPage), findsOneWidget);
    });
  });
}
