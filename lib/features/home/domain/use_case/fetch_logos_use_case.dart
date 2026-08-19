import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';
import 'package:glitch_tv/features/home/domain/repo/repo/home_repo.dart';

class FetchLogosUseCase {
  final HomeRepo _homeRepo;
  FetchLogosUseCase(this._homeRepo);

  Future<ApiResult<List<LogosResponseEntity>>> call() {
    return _homeRepo.fetchLogos();
  }
}