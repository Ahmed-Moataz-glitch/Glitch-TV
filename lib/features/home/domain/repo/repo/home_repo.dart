import 'package:glitch_tv/features/home/data/api/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';

abstract class HomeRepo {
  Future<ApiResult<LogosResponseEntity>> fetchLogos();

  Future<ApiResult<ChannelsResponseEntity>> fetchChannels();
}