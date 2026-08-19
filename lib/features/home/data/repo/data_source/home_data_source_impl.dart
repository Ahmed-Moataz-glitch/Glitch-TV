import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/data/api/home_api.dart';
import 'package:glitch_tv/features/home/data/models/channels_response_dto.dart';
import 'package:glitch_tv/features/home/data/models/logos_response_dto.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';
import 'package:glitch_tv/features/home/domain/repo/data_source/home_data_source.dart';

class HomeDataSourceImpl extends HomeDataSource {
  final HomeApi _homeApi;
  HomeDataSourceImpl(this._homeApi);

  @override
  Future<ApiResult<List<ChannelsResponseEntity>>> fetchChannels() async {
    final result = await _homeApi.fetchChannels();
    switch(result) {
      case ApiSuccess<List<ChannelsResponseDto>>():
        final entities = result.data?.map((e) => e.toEntity()).toList() ?? [];
        return ApiSuccess<List<ChannelsResponseEntity>>(entities);
      case ApiError<List<ChannelsResponseDto>>():
        return ApiError<List<ChannelsResponseEntity>>(result.message);
    }
  }

  @override
  Future<ApiResult<List<LogosResponseEntity>>> fetchLogos() async {
    final result = await _homeApi.fetchLogos();
    switch(result) {
      case ApiSuccess<List<LogosResponseDto>>():
        final entities = result.data?.map((e) => e.toEntity()).toList() ?? [];
        return ApiSuccess<List<LogosResponseEntity>>(entities);
      case ApiError<List<LogosResponseDto>>():
        return ApiError<List<LogosResponseEntity>>(result.message);
    }
  }
}
