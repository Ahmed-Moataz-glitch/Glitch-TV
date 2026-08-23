import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';

abstract class PodcastDetailsDataSource {
  Future<ApiResult<List<PodcastEpisodeEntity>>> fetchEpisodes({
    required String feedUrl,
    String fallbackArtwork = '',
    bool forceRefresh = false,
  });
}
