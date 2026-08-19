import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';

abstract class HomeDataSource {
  Future<ApiResult<List<LogosResponseEntity>>> fetchLogos();

  Future<ApiResult<List<ChannelsResponseEntity>>> fetchChannels();
}
