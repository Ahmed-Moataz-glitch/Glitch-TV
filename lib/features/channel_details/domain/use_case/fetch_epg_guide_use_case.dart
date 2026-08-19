import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/epg_programme_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/repo/channel_details_repo.dart';

class FetchEpgGuideUseCase {
  final ChannelDetailsRepo _repo;
  FetchEpgGuideUseCase(this._repo);

  Future<ApiResult<List<EpgProgrammeEntity>>> call({bool forceRefresh = false}) {
    return _repo.fetchEpgGuide(forceRefresh: forceRefresh);
  }
}
