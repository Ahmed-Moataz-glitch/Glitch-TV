import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';
import 'package:glitch_tv/features/home/domain/repo/repo/home_repo.dart';

class FetchRadioStationsUseCase {
  final HomeRepo repo;
  FetchRadioStationsUseCase(this.repo);

  Future<ApiResult<List<RadioStationEntity>>> call({bool forceRefresh = false}) async {
    return await repo.fetchRadioStations(forceRefresh: forceRefresh);
  }
}
