import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/channel_details/data/api/channel_details_api.dart';
import 'package:glitch_tv/features/channel_details/data/models/channel_stream_dto.dart';
import 'package:glitch_tv/features/channel_details/data/models/epg_programme_dto.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/channel_stream_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/epg_programme_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/data_source/channel_details_data_source.dart';
import 'package:glitch_tv/features/home/data/models/channels_model.dart';

class ChannelDetailsDataSourceImpl extends ChannelDetailsDataSource {
  final ChannelDetailsApi _api;
  ChannelDetailsDataSourceImpl(this._api);

  @override
  Future<ApiResult<List<EpgProgrammeEntity>>> fetchEpgGuide({bool forceRefresh = false}) async {
    final result = await _api.fetchEpgGuide(forceRefresh: forceRefresh);
    switch (result) {
      case ApiSuccess<List<EpgProgrammeDto>>():
        final entities = result.data?.map((e) => e.toEntity()).toList() ?? [];
        return ApiSuccess<List<EpgProgrammeEntity>>(entities);
      case ApiError<List<EpgProgrammeDto>>():
        return ApiError<List<EpgProgrammeEntity>>(result.message);
    }
  }

  @override
  Future<ApiResult<List<ChannelStreamEntity>>> fetchStreamsForChannel(
    String channelId, {
    bool forceRefresh = false,
  }) async {
    final target = channelId.trim();

    // Check if channelId exists in channelsStreams map
    String? customUrl;
    for (var key in channelsStreams.keys) {
      if (key.toLowerCase().trim() == target.toLowerCase()) {
        customUrl = channelsStreams[key];
        break;
      }
    }

    final List<ChannelStreamEntity> customEntities = [];
    if (customUrl != null && customUrl.isNotEmpty) {
      customEntities.add(
        ChannelStreamEntity(
          channelId: channelId,
          title: 'Official Live Stream',
          url: customUrl,
          quality: 'HD Stream',
          label: 'Official Stream',
        ),
      );
    }

    final result = await _api.fetchStreams(forceRefresh: forceRefresh);
    switch (result) {
      case ApiSuccess<List<ChannelStreamDto>>():
        final lowerTarget = target.toLowerCase();

        // 1. Strict exact channel ID match (e.g. "SpacetoonArabic.ae")
        var matched = (result.data ?? [])
            .where((s) => s.channel != null && s.channel!.toLowerCase().trim() == lowerTarget)
            .toList();

        // 2. Fallback ONLY if no exact channel ID match exists
        if (matched.isEmpty) {
          final prefix = lowerTarget.split('.').first;
          matched = (result.data ?? [])
              .where((s) =>
                  (s.channel != null && s.channel!.toLowerCase().trim() == prefix) ||
                  (s.title != null && s.title!.toLowerCase().trim() == lowerTarget))
              .toList();
        }

        final apiEntities = matched.map((s) => s.toEntity()).toList();

        // Prioritize direct fast HLS/video streams first, web pages as secondary
        final directStreams = apiEntities.where((s) {
          final u = s.url.toLowerCase();
          return u.contains('.m3u8') || u.contains('.mp4') || u.contains('.ts') || u.contains('.m3u');
        }).toList();

        final otherApiStreams = apiEntities.where((s) => !directStreams.contains(s)).toList();

        final combined = [...directStreams, ...otherApiStreams, ...customEntities];

        return ApiSuccess<List<ChannelStreamEntity>>(
          combined.isNotEmpty
              ? combined
              : (customEntities.isNotEmpty ? customEntities : []),
        );
      case ApiError<List<ChannelStreamDto>>():
        if (customEntities.isNotEmpty) {
          return ApiSuccess<List<ChannelStreamEntity>>(customEntities);
        }
        return ApiError<List<ChannelStreamEntity>>(result.message);
    }
  }
}
