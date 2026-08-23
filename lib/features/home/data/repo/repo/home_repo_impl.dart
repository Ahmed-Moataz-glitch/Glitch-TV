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
  Future<ApiResult<List<ChannelsResponseEntity>>> fetchChannels() async {
    return await _homeDataSource.fetchChannels();
  }

  @override
  Future<ApiResult<List<LogosResponseEntity>>> fetchLogos() async {
    return await _homeDataSource.fetchLogos();
  }

  @override
  Future<ApiResult<List<RadioStationEntity>>> fetchRadioStations() async {
    return await _homeDataSource.fetchRadioStations();
  }

  @override
  Future<ApiResult<List<PodcastEntity>>> fetchPodcasts() async {
    return await _homeDataSource.fetchPodcasts();
  }
}
