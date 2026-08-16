import 'package:glitch_tv/features/home/data/api/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';
import 'package:glitch_tv/features/home/domain/repo/data_source/home_data_source.dart';
import 'package:glitch_tv/features/home/domain/repo/repo/home_repo.dart';

class HomeRepoImpl extends HomeRepo {
  final HomeDataSource _homeDataSource;
  HomeRepoImpl(this._homeDataSource);

  @override
  Future<ApiResult<ChannelsResponseEntity>> fetchChannels() async {
    return await _homeDataSource.fetchChannels();
  }

  @override
  Future<ApiResult<LogosResponseEntity>> fetchLogos() async {
    return await _homeDataSource.fetchLogos();
  }
}
