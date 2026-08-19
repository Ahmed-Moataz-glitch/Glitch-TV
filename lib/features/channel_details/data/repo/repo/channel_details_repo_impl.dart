import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/epg_programme_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/data_source/channel_details_data_source.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/repo/channel_details_repo.dart';

class ChannelDetailsRepoImpl extends ChannelDetailsRepo {
  final ChannelDetailsDataSource _dataSource;
  ChannelDetailsRepoImpl(this._dataSource);

  @override
  Future<ApiResult<List<EpgProgrammeEntity>>> fetchEpgGuide({bool forceRefresh = false}) {
    return _dataSource.fetchEpgGuide(forceRefresh: forceRefresh);
  }
}
