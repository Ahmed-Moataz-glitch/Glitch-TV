import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/channel_stream_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/use_case/fetch_channel_streams_use_case.dart';
import 'package:glitch_tv/features/channel_details/presentation/view_model/channel_stream_state.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';

class ChannelStreamCubit extends Cubit<ChannelStreamState> {
  final FetchChannelStreamsUseCase fetchChannelStreamsUseCase;
  final ChannelItemEntity channelItem;

  ChannelStreamCubit({
    required this.fetchChannelStreamsUseCase,
    required this.channelItem,
  }) : super(const ChannelStreamInitial());

  Future<void> loadStreams({bool forceRefresh = false}) async {
    emit(const ChannelStreamLoading());
    final result = await fetchChannelStreamsUseCase(
      channelItem.channel.id,
      forceRefresh: forceRefresh,
    );

    switch (result) {
      case ApiSuccess<List<ChannelStreamEntity>>():
        final streams = result.data ?? [];
        if (streams.isEmpty) {
          emit(const ChannelStreamError('No active stream found for this channel.'));
        } else {
          emit(ChannelStreamSuccess(
            streams: streams,
            selectedStream: streams.first,
          ));
        }
      case ApiError<List<ChannelStreamEntity>>():
        emit(ChannelStreamError(result.message));
    }
  }

  void selectStream(ChannelStreamEntity stream) {
    if (state is ChannelStreamSuccess) {
      final current = state as ChannelStreamSuccess;
      emit(ChannelStreamSuccess(
        streams: current.streams,
        selectedStream: stream,
      ));
    }
  }
}
