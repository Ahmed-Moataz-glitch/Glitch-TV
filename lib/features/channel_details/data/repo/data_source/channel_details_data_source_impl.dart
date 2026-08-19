import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/channel_details/data/api/channel_details_api.dart';
import 'package:glitch_tv/features/channel_details/data/models/channel_stream_dto.dart';
import 'package:glitch_tv/features/channel_details/data/models/epg_programme_dto.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/channel_stream_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/epg_programme_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/data_source/channel_details_data_source.dart';

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
    final result = await _api.fetchStreams(forceRefresh: forceRefresh);
    switch (result) {
      case ApiSuccess<List<ChannelStreamDto>>():
        final target = channelId.toLowerCase().trim();

        // 1. Strict exact channel ID match (e.g. "SpacetoonArabic.ae")
        var matched = (result.data ?? [])
            .where((s) => s.channel != null && s.channel!.toLowerCase().trim() == target)
            .toList();

        // 2. Fallback ONLY if no exact channel ID match exists
        if (matched.isEmpty) {
          final prefix = target.split('.').first;
          matched = (result.data ?? [])
              .where((s) =>
                  (s.channel != null && s.channel!.toLowerCase().trim() == prefix) ||
                  (s.title != null && s.title!.toLowerCase().trim() == target))
              .toList();
        }

        final entities = matched.map((s) => s.toEntity()).toList();
        return ApiSuccess<List<ChannelStreamEntity>>(entities);
      case ApiError<List<ChannelStreamDto>>():
        return ApiError<List<ChannelStreamEntity>>(result.message);
    }
  }
}
