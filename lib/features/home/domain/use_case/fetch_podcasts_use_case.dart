import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/home/domain/repo/repo/home_repo.dart';

class FetchPodcastsUseCase {
  final HomeRepo repo;
  FetchPodcastsUseCase(this.repo);

  Future<ApiResult<List<PodcastEntity>>> call() async {
    return await repo.fetchPodcasts();
  }
}
