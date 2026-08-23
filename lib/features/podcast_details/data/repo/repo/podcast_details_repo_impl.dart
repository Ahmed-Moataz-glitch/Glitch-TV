import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';
import 'package:glitch_tv/features/podcast_details/domain/repo/data_source/podcast_details_data_source.dart';
import 'package:glitch_tv/features/podcast_details/domain/repo/repo/podcast_details_repo.dart';

class PodcastDetailsRepoImpl extends PodcastDetailsRepo {
  final PodcastDetailsDataSource _dataSource;

  PodcastDetailsRepoImpl(this._dataSource);

  @override
  Future<ApiResult<List<PodcastEpisodeEntity>>> fetchEpisodes({
    required String feedUrl,
    String fallbackArtwork = '',
    bool forceRefresh = false,
  }) async {
    return await _dataSource.fetchEpisodes(
      feedUrl: feedUrl,
      fallbackArtwork: fallbackArtwork,
      forceRefresh: forceRefresh,
    );
  }
}
