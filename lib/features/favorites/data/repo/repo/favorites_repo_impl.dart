import 'package:glitch_tv/features/favorites/data/models/favorite_channel_dto.dart';
import 'package:glitch_tv/features/favorites/domain/repo/data_source/favorites_local_data_source.dart';
import 'package:glitch_tv/features/favorites/domain/repo/repo/favorites_repo.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';

class FavoritesRepoImpl implements FavoritesRepo {
  final FavoritesLocalDataSource _localDataSource;

  FavoritesRepoImpl(this._localDataSource);

  @override
  Future<List<ChannelItemEntity>> getFavoriteChannels() async {
    final dtos = await _localDataSource.getFavoriteChannels();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<bool> toggleFavoriteChannel(ChannelItemEntity channel) async {
    final isFav = await _localDataSource.isFavoriteChannel(channel.channel.id);
    if (isFav) {
      await _localDataSource.removeFavoriteChannel(channel.channel.id);
      return false;
    } else {
      await _localDataSource.saveFavoriteChannel(
        FavoriteChannelDto.fromEntity(channel),
      );
      return true;
    }
  }

  @override
  Future<void> removeFavoriteChannel(String channelId) async {
    await _localDataSource.removeFavoriteChannel(channelId);
  }

  @override
  Future<bool> isFavoriteChannel(String channelId) async {
    return await _localDataSource.isFavoriteChannel(channelId);
  }
}
