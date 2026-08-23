import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/channel_stream_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/epg_programme_entity.dart';

abstract class ChannelDetailsRepo {
  Future<ApiResult<List<EpgProgrammeEntity>>> fetchEpgGuide({bool forceRefresh = false});
  Future<ApiResult<List<ChannelStreamEntity>>> fetchStreamsForChannel(String channelId, {bool forceRefresh = false});
}
