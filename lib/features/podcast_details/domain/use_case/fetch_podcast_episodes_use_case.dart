import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';
import 'package:glitch_tv/features/podcast_details/domain/repo/repo/podcast_details_repo.dart';

class FetchPodcastEpisodesUseCase {
  final PodcastDetailsRepo _repo;

  FetchPodcastEpisodesUseCase(this._repo);

  Future<ApiResult<List<PodcastEpisodeEntity>>> call({
    required String feedUrl,
    String fallbackArtwork = '',
    bool forceRefresh = false,
  }) async {
    return await _repo.fetchEpisodes(
      feedUrl: feedUrl,
      fallbackArtwork: fallbackArtwork,
      forceRefresh: forceRefresh,
    );
  }
}
