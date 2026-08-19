import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';

class ChannelItemEntity {
  final ChannelsResponseEntity channel;
  final String logoUrl;

  const ChannelItemEntity({
    required this.channel,
    required this.logoUrl,
  });
}
