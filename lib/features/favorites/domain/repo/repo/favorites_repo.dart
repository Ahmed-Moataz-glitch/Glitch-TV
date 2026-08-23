import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';

abstract class FavoritesRepo {
  Future<List<ChannelItemEntity>> getFavoriteChannels();
  Future<bool> toggleFavoriteChannel(ChannelItemEntity channel);
  Future<void> removeFavoriteChannel(String channelId);
  Future<bool> isFavoriteChannel(String channelId);
}
