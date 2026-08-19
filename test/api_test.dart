import 'package:flutter_test/flutter_test.dart';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/data/api/home_api.dart';
import 'package:glitch_tv/features/home/data/models/channels_model.dart';
import 'package:glitch_tv/features/home/data/models/channels_response_dto.dart';
import 'package:glitch_tv/features/home/data/models/logos_response_dto.dart';

void main() {
  test('HomeApi fetchLogos returns valid data', () async {
    final api = HomeApi();
    final result = await api.fetchLogos();
    if (result is ApiSuccess<List<LogosResponseDto>>) {
      expect(result.data, isNotNull);
      expect(result.data!, isNotEmpty);
    } else if (result is ApiError<List<LogosResponseDto>>) {
      fail(result.message);
    }
  });

  test('HomeApi fetchChannels returns valid data', () async {
    final api = HomeApi();
    final result = await api.fetchChannels();
    if (result is ApiSuccess<List<ChannelsResponseDto>>) {
      expect(result.data, isNotNull);
      expect(result.data!, isNotEmpty);
    } else if (result is ApiError<List<ChannelsResponseDto>>) {
      fail(result.message);
    }
  });

  test('channels in channels_model are matched in API', () async {
    final api = HomeApi();
    final logosRes = await api.fetchLogos();
    final channelsRes = await api.fetchChannels();

    final logos = (logosRes as ApiSuccess<List<LogosResponseDto>>).data!;
    final chs = (channelsRes as ApiSuccess<List<ChannelsResponseDto>>).data!;

    final logoMap = {
      for (var l in logos)
        if (l.inUse == true && (l.url?.isNotEmpty ?? false))
          l.channel!.toLowerCase(): l.url
    };
    final chMap = {for (var c in chs) c.id!.toLowerCase(): c};

    final missingLogos = <String>[];
    for (var id in channels) {
      if (!logoMap.containsKey(id.toLowerCase())) {
        missingLogos.add(id);
      }
      expect(chMap.containsKey(id.toLowerCase()), isTrue,
          reason: '$id missing in channels API');
    }
    expect(missingLogos, isEmpty,
        reason: 'Channels missing in logo API: $missingLogos');
  });
}
