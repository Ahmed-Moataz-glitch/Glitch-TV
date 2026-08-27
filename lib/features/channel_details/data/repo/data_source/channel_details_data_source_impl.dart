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

    // 1. Check verifiedChannelStreams map first for tested direct HLS streams
    VerifiedChannelStream? verified;
    for (var key in verifiedChannelStreams.keys) {
      if (key.toLowerCase().trim() == target.toLowerCase()) {
        verified = verifiedChannelStreams[key];
        break;
      }
    }

    final List<ChannelStreamEntity> verifiedEntities = [];
    if (verified != null) {
      verifiedEntities.add(
        ChannelStreamEntity(
          channelId: channelId,
          title: verified.title,
          url: verified.url,
          quality: verified.quality,
          label: 'Direct Stream (HD)',
          referrer: verified.referrer,
          userAgent: verified.userAgent,
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

        // 2. Fallback if no exact channel ID match exists
        if (matched.isEmpty) {
          final prefix = lowerTarget.split('.').first;
          matched = (result.data ?? [])
              .where((s) =>
                  (s.channel != null && s.channel!.toLowerCase().trim() == prefix) ||
                  (s.title != null && s.title!.toLowerCase().trim() == lowerTarget))
              .toList();
        }

        final apiEntities = matched.map((s) => s.toEntity()).toList();

        // Combine verified streams first, followed by deduplicated API streams
        final List<ChannelStreamEntity> uniqueStreams = [...verifiedEntities];
        final Set<String> seenUrls = verifiedEntities.map((e) => e.url.toLowerCase()).toSet();

        for (var entity in apiEntities) {
          final u = entity.url.toLowerCase().trim();
          if (!seenUrls.contains(u)) {
            seenUrls.add(u);
            uniqueStreams.add(entity);
          }
        }

        return ApiSuccess<List<ChannelStreamEntity>>(
          uniqueStreams.isNotEmpty ? uniqueStreams : verifiedEntities,
        );
      case ApiError<List<ChannelStreamDto>>():
        if (verifiedEntities.isNotEmpty) {
          return ApiSuccess<List<ChannelStreamEntity>>(verifiedEntities);
        }
        return ApiError<List<ChannelStreamEntity>>(result.message);
    }
  }
}
