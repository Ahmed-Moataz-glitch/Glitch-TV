import 'package:glitch_tv/features/favorites/domain/repo/repo/favorites_repo.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';

class ToggleFavoriteChannelUseCase {
  final FavoritesRepo _repo;

  ToggleFavoriteChannelUseCase(this._repo);

  Future<bool> call(ChannelItemEntity channel) async {
    return await _repo.toggleFavoriteChannel(channel);
  }
}
