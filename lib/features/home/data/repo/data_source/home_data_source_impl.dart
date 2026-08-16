import 'package:glitch_tv/features/home/data/api/api_result.dart';
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
  Future<ApiResult<ChannelsResponseEntity>> fetchChannels() async {
    final result = await _homeApi.fetchChannels();
    switch(result) {
      case ApiSuccess<ChannelsResponseDto>():
        return ApiSuccess<ChannelsResponseEntity>(result.data?.toEntity());
      case ApiError<ChannelsResponseDto>():
        return ApiError<ChannelsResponseEntity>(result.message);
    }
  }

  @override
  Future<ApiResult<LogosResponseEntity>> fetchLogos() async {
    final result = await _homeApi.fetchLogos();
    switch(result) {
      case ApiSuccess<LogosResponseDto>():
        return ApiSuccess<LogosResponseEntity>(result.data?.toEntity());
      case ApiError<LogosResponseDto>():
        return ApiError<LogosResponseEntity>(result.message);
    }
  }
}
