import 'package:glitch_tv/features/favorites/data/models/favorite_channel_dto.dart';

abstract class FavoritesLocalDataSource {
  Future<List<FavoriteChannelDto>> getFavoriteChannels();
  Future<void> saveFavoriteChannel(FavoriteChannelDto channel);
  Future<void> removeFavoriteChannel(String channelId);
  Future<bool> isFavoriteChannel(String channelId);
}
