import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/podcast_details/data/api/podcast_details_api.dart';
import 'package:glitch_tv/features/podcast_details/data/models/podcast_episode_dto.dart';
import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';
import 'package:glitch_tv/features/podcast_details/domain/repo/data_source/podcast_details_data_source.dart';

class PodcastDetailsDataSourceImpl extends PodcastDetailsDataSource {
  final PodcastDetailsApi _api;

  PodcastDetailsDataSourceImpl(this._api);

  @override
  Future<ApiResult<List<PodcastEpisodeEntity>>> fetchEpisodes({
    required String feedUrl,
    String fallbackArtwork = '',
    bool forceRefresh = false,
  }) async {
    final result = await _api.fetchEpisodes(
      feedUrl: feedUrl,
      fallbackArtwork: fallbackArtwork,
      forceRefresh: forceRefresh,
    );

    switch (result) {
      case ApiSuccess<List<PodcastEpisodeDto>>():
        final entities =
            result.data?.map((dto) => dto.toEntity()).toList() ?? [];
        return ApiSuccess<List<PodcastEpisodeEntity>>(entities);
      case ApiError<List<PodcastEpisodeDto>>():
        return ApiError<List<PodcastEpisodeEntity>>(result.message);
    }
  }
}
