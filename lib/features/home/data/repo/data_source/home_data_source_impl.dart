import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/data/api/home_api.dart';
import 'package:glitch_tv/features/home/data/models/channels_response_dto.dart';
import 'package:glitch_tv/features/home/data/models/logos_response_dto.dart';
import 'package:glitch_tv/features/home/data/models/podcast_dto.dart';
import 'package:glitch_tv/features/home/data/models/radio_station_dto.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';
import 'package:glitch_tv/features/home/domain/repo/data_source/home_data_source.dart';

class HomeDataSourceImpl extends HomeDataSource {
  final HomeApi _homeApi;
  HomeDataSourceImpl(this._homeApi);

  @override
  Future<ApiResult<List<ChannelsResponseEntity>>> fetchChannels({bool forceRefresh = false}) async {
    final result = await _homeApi.fetchChannels(forceRefresh: forceRefresh);
    switch(result) {
      case ApiSuccess<List<ChannelsResponseDto>>():
        final entities = result.data?.map((e) => e.toEntity()).toList() ?? [];
        return ApiSuccess<List<ChannelsResponseEntity>>(entities);
      case ApiError<List<ChannelsResponseDto>>():
        return ApiError<List<ChannelsResponseEntity>>(result.message);
    }
  }

  @override
  Future<ApiResult<List<LogosResponseEntity>>> fetchLogos({bool forceRefresh = false}) async {
    final result = await _homeApi.fetchLogos(forceRefresh: forceRefresh);
    switch(result) {
      case ApiSuccess<List<LogosResponseDto>>():
        final entities = result.data?.map((e) => e.toEntity()).toList() ?? [];
        return ApiSuccess<List<LogosResponseEntity>>(entities);
      case ApiError<List<LogosResponseDto>>():
        return ApiError<List<LogosResponseEntity>>(result.message);
    }
  }

  @override
  Future<ApiResult<List<RadioStationEntity>>> fetchRadioStations({bool forceRefresh = false}) async {
    final result = await _homeApi.fetchRadioStations(forceRefresh: forceRefresh);
    switch (result) {
      case ApiSuccess<List<RadioStationDto>>():
        final entities = result.data?.map((e) => e.toEntity()).toList() ?? [];
        return ApiSuccess<List<RadioStationEntity>>(entities);
      case ApiError<List<RadioStationDto>>():
        return ApiError<List<RadioStationEntity>>(result.message);
    }
  }

  @override
  Future<ApiResult<List<PodcastEntity>>> fetchPodcasts({bool forceRefresh = false}) async {
    final result = await _homeApi.fetchPodcasts(forceRefresh: forceRefresh);
    switch (result) {
      case ApiSuccess<List<PodcastDto>>():
        final entities = result.data?.map((e) => e.toEntity()).toList() ?? [];
        return ApiSuccess<List<PodcastEntity>>(entities);
      case ApiError<List<PodcastDto>>():
        return ApiError<List<PodcastEntity>>(result.message);
    }
  }
}
