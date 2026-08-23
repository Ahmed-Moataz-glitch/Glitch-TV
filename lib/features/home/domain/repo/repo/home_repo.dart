import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';

abstract class HomeRepo {
  Future<ApiResult<List<LogosResponseEntity>>> fetchLogos();

  Future<ApiResult<List<ChannelsResponseEntity>>> fetchChannels();

  Future<ApiResult<List<RadioStationEntity>>> fetchRadioStations();

  Future<ApiResult<List<PodcastEntity>>> fetchPodcasts();
}