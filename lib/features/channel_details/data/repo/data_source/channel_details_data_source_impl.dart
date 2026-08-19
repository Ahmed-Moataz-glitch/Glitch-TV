import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/channel_details/data/api/channel_details_api.dart';
import 'package:glitch_tv/features/channel_details/data/models/epg_programme_dto.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/epg_programme_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/data_source/channel_details_data_source.dart';

class ChannelDetailsDataSourceImpl extends ChannelDetailsDataSource {
  final ChannelDetailsApi _api;
  ChannelDetailsDataSourceImpl(this._api);

  @override
  Future<ApiResult<List<EpgProgrammeEntity>>> fetchEpgGuide({bool forceRefresh = false}) async {
    final result = await _api.fetchEpgGuide(forceRefresh: forceRefresh);
    switch (result) {
      case ApiSuccess<List<EpgProgrammeDto>>():
        final entities = result.data?.map((e) => e.toEntity()).toList() ?? [];
        return ApiSuccess<List<EpgProgrammeEntity>>(entities);
      case ApiError<List<EpgProgrammeDto>>():
        return ApiError<List<EpgProgrammeEntity>>(result.message);
    }
  }
}
