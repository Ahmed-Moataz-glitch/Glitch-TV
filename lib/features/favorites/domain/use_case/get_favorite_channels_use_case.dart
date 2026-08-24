import 'package:glitch_tv/features/favorites/domain/repo/repo/favorites_repo.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';

class GetFavoriteChannelsUseCase {
  final FavoritesRepo _repo;

  GetFavoriteChannelsUseCase(this._repo);

  Future<List<ChannelItemEntity>> call() async {
    return await _repo.getFavoriteChannels();
  }
}
