import 'package:glitch_tv/features/channel_details/domain/entities/channel_stream_entity.dart';

abstract class ChannelStreamState {
  const ChannelStreamState();
}

class ChannelStreamInitial extends ChannelStreamState {
  const ChannelStreamInitial();
}

class ChannelStreamLoading extends ChannelStreamState {
  const ChannelStreamLoading();
}

class ChannelStreamSuccess extends ChannelStreamState {
  final List<ChannelStreamEntity> streams;
  final ChannelStreamEntity selectedStream;

  const ChannelStreamSuccess({
    required this.streams,
    required this.selectedStream,
  });
}

class ChannelStreamError extends ChannelStreamState {
  final String message;

  const ChannelStreamError(this.message);
}
