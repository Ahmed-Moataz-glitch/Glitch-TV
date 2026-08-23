import 'dart:convert';
import 'package:glitch_tv/features/favorites/data/models/favorite_channel_dto.dart';
import 'package:glitch_tv/features/favorites/domain/repo/data_source/favorites_local_data_source.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  static const String boxName = 'favorite_channels_box';

  Future<Box<dynamic>> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<dynamic>(boxName);
    }
    return await Hive.openBox<dynamic>(boxName);
  }

  @override
  Future<List<FavoriteChannelDto>> getFavoriteChannels() async {
    final box = await _getBox();
    final List<FavoriteChannelDto> channels = [];
    for (var key in box.keys) {
      final value = box.get(key);
      if (value != null) {
        if (value is String) {
          final map = jsonDecode(value) as Map<String, dynamic>;
          channels.add(FavoriteChannelDto.fromJson(map));
        } else if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          channels.add(FavoriteChannelDto.fromJson(map));
        }
      }
    }
    return channels;
  }

  @override
  Future<void> saveFavoriteChannel(FavoriteChannelDto channel) async {
    final box = await _getBox();
    final jsonStr = jsonEncode(channel.toJson());
    await box.put(channel.id.toLowerCase(), jsonStr);
  }

  @override
  Future<void> removeFavoriteChannel(String channelId) async {
    final box = await _getBox();
    await box.delete(channelId.toLowerCase());
  }

  @override
  Future<bool> isFavoriteChannel(String channelId) async {
    final box = await _getBox();
    return box.containsKey(channelId.toLowerCase());
  }
}
