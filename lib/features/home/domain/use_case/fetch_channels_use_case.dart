import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:glitch_tv/features/home/domain/repo/repo/home_repo.dart';

class FetchChannelsUseCase {
  final HomeRepo _homeRepo;
  FetchChannelsUseCase(this._homeRepo);

  Future<ApiResult<List<ChannelsResponseEntity>>> call() {
    return _homeRepo.fetchChannels();
  }
}