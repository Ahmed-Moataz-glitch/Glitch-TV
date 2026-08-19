import 'package:flutter_test/flutter_test.dart';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/channel_details/data/api/channel_details_api.dart';
import 'package:glitch_tv/features/channel_details/data/models/epg_programme_dto.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/epg_programme_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/use_case/fetch_epg_guide_use_case.dart';
import 'package:glitch_tv/features/channel_details/presentation/view_model/channel_details_cubit.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';

void main() {
  group('Channel Details Feature Tests', () {
    test('EpgProgrammeDto parses date correctly', () {
      const rawDate = '20260818143000 +0000';
      final dt = EpgProgrammeDto.parseEpgDate(rawDate);
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 8);
      expect(dt.day, 18);
    });

    test('parseXmlContent handles preambles and unescaped &', () {
      const rawXml = '''
Some header text before xml preamble
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20260818143000 +0000" stop="20260818153000 +0000" channel="OnE.eg">
    <title>Tom & Jerry Show</title>
    <desc>Fun & Entertainment</desc>
  </programme>
</tv>
''';

      final dtos = ChannelDetailsApi.parseXmlContent(rawXml);
      expect(dtos, isNotEmpty);
      expect(dtos.first.channel, 'OnE.eg');
      expect(dtos.first.title, contains('Tom & Jerry'));
    });

    test('parseXmlContent handles malformed XML via RegExp fallback', () {
      const malformedXml = '''
<tv>
  <programme start="20260818143000 +0000" stop="20260818153000 +0000" channel="OnE.eg">
    <title>Broken <Tag Title</title>
    <desc>Unclosed description
  </programme>
</tv>
''';

      final dtos = ChannelDetailsApi.parseXmlContent(malformedXml);
      expect(dtos, isNotEmpty);
      expect(dtos.first.channel, 'OnE.eg');
    });

    test('EpgProgrammeEntity isToday check', () {
      final now = DateTime.now();
      final programme = EpgProgrammeEntity(
        channelId: 'OnE.eg',
        title: 'Test Show',
        subTitle: 'Episode 1',
        description: 'Test description',
        startRaw: '20260818143000 +0000',
        stopRaw: '20260818153000 +0000',
        startTime: now.subtract(const Duration(minutes: 30)),
        stopTime: now.add(const Duration(minutes: 30)),
      );

      expect(programme.isToday, isTrue);
      expect(programme.isLive, isTrue);
    });

    test('ChannelDetailsCubit initializes and filters correctly', () async {
      final mockUseCase = MockFetchEpgGuideUseCase();
      final dummyChannelItem = ChannelItemEntity(
        channel: ChannelsResponseEntity(
          id: 'OnE.eg',
          name: 'ON E',
          altNames: [],
          network: '',
          owners: [],
          country: 'EG',
          categories: ['General'],
          isNsfw: false,
          launched: '',
          closed: '',
          replacedBy: '',
          website: '',
        ),
        logoUrl: 'https://example.com/logo.png',
      );

      final cubit = ChannelDetailsCubit(
        fetchEpgGuideUseCase: mockUseCase,
        channelItem: dummyChannelItem,
      );

      expect(cubit.state, isA<ChannelDetailsInitial>());

      await cubit.loadEpg();

      expect(cubit.state, isA<ChannelDetailsSuccess>());
      final success = cubit.state as ChannelDetailsSuccess;
      expect(success.todayProgrammes.length, 1);
      expect(success.todayProgrammes.first.title, 'Live Show');
    });
  });
}

class MockFetchEpgGuideUseCase implements FetchEpgGuideUseCase {
  @override
  Future<ApiResult<List<EpgProgrammeEntity>>> call({bool forceRefresh = false}) async {
    final now = DateTime.now();
    return ApiSuccess([
      EpgProgrammeEntity(
        channelId: 'OnE.eg',
        title: 'Live Show',
        subTitle: 'Season 1',
        description: 'Live description',
        startRaw: '20260818143000 +0000',
        stopRaw: '20260818153000 +0000',
        startTime: now.subtract(const Duration(minutes: 10)),
        stopTime: now.add(const Duration(minutes: 50)),
      ),
    ]);
  }
}
