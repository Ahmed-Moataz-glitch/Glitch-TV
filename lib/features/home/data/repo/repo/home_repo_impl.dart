import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';
import 'package:glitch_tv/features/home/domain/repo/data_source/home_data_source.dart';
import 'package:glitch_tv/features/home/domain/repo/repo/home_repo.dart';

class HomeRepoImpl extends HomeRepo {
  final HomeDataSource _homeDataSource;
  HomeRepoImpl(this._homeDataSource);

  @override
  Future<ApiResult<List<ChannelsResponseEntity>>> fetchChannels({bool forceRefresh = false}) async {
    return await _homeDataSource.fetchChannels(forceRefresh: forceRefresh);
  }

  @override
  Future<ApiResult<List<LogosResponseEntity>>> fetchLogos({bool forceRefresh = false}) async {
    return await _homeDataSource.fetchLogos(forceRefresh: forceRefresh);
  }

  @override
  Future<ApiResult<List<RadioStationEntity>>> fetchRadioStations({bool forceRefresh = false}) async {
    return await _homeDataSource.fetchRadioStations(forceRefresh: forceRefresh);
  }

  @override
  Future<ApiResult<List<PodcastEntity>>> fetchPodcasts({bool forceRefresh = false}) async {
    return await _homeDataSource.fetchPodcasts(forceRefresh: forceRefresh);
  }
}
