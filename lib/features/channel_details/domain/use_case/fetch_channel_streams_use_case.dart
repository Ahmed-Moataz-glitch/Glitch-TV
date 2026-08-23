import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/channel_stream_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/repo/channel_details_repo.dart';

class FetchChannelStreamsUseCase {
  final ChannelDetailsRepo repo;

  FetchChannelStreamsUseCase(this.repo);

  Future<ApiResult<List<ChannelStreamEntity>>> call(
    String channelId, {
    bool forceRefresh = false,
  }) {
    return repo.fetchStreamsForChannel(channelId, forceRefresh: forceRefresh);
  }
}
