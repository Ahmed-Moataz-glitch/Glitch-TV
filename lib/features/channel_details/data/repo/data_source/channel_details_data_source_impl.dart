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
    final lowerTarget = target.toLowerCase();

    // 1. Get verified working streams for this channel ID
    final List<ChannelStreamEntity> verifiedEntities = [];
    for (var entry in verifiedChannelStreams.entries) {
      if (entry.key.toLowerCase().trim() == lowerTarget) {
        for (var v in entry.value) {
          verifiedEntities.add(
            ChannelStreamEntity(
              channelId: channelId,
              title: v.title,
              url: v.url,
              quality: v.quality,
              label: v.label ?? 'Direct Stream (HD)',
              referrer: v.referrer,
              userAgent: v.userAgent,
            ),
          );
        }
        break;
      }
    }

    // 2. Fetch API streams for this channel
    try {
      final result = await _api.fetchStreams(forceRefresh: forceRefresh);
      switch (result) {
        case ApiSuccess<List<ChannelStreamDto>>():
          final allStreams = result.data ?? [];

          // Exact and prefix matching
          var matched = allStreams
              .where((s) => s.channel != null && s.channel!.toLowerCase().trim() == lowerTarget)
              .toList();

          if (matched.isEmpty) {
            final prefix = lowerTarget.split('.').first;
            matched = allStreams
                .where((s) =>
                    (s.channel != null && s.channel!.toLowerCase().trim() == prefix) ||
                    (s.title != null && s.title!.toLowerCase().trim() == lowerTarget))
                .toList();
          }

          final apiEntities = matched.map((s) => s.toEntity()).toList();

          // Merge verified streams first, then deduplicated API streams
          final List<ChannelStreamEntity> combined = [...verifiedEntities];
          final Set<String> seenUrls = verifiedEntities.map((e) => e.url.toLowerCase().trim()).toSet();

          for (var entity in apiEntities) {
            final u = entity.url.toLowerCase().trim();
            if (!seenUrls.contains(u)) {
              seenUrls.add(u);
              combined.add(entity);
            }
          }

          if (combined.isNotEmpty) {
            return ApiSuccess<List<ChannelStreamEntity>>(combined);
          }
          break;

        case ApiError<List<ChannelStreamDto>>():
          if (verifiedEntities.isNotEmpty) {
            return ApiSuccess<List<ChannelStreamEntity>>(verifiedEntities);
          }
          return ApiError<List<ChannelStreamEntity>>(result.message);
      }
    } catch (_) {
      if (verifiedEntities.isNotEmpty) {
        return ApiSuccess<List<ChannelStreamEntity>>(verifiedEntities);
      }
    }

    if (verifiedEntities.isNotEmpty) {
      return ApiSuccess<List<ChannelStreamEntity>>(verifiedEntities);
    }

    return ApiError<List<ChannelStreamEntity>>('No active stream found for $channelId.');
  }
}
