import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:glitch_tv/features/favorites/data/models/favorite_channel_dto.dart';
import 'package:glitch_tv/features/favorites/data/repo/data_source/favorites_local_data_source_impl.dart';
import 'package:glitch_tv/features/favorites/data/repo/repo/favorites_repo_impl.dart';
import 'package:glitch_tv/features/favorites/domain/use_case/get_favorite_channels_use_case.dart';
import 'package:glitch_tv/features/favorites/domain/use_case/toggle_favorite_channel_use_case.dart';
import 'package:glitch_tv/features/favorites/presentation/view_model/favorites_cubit.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;
  late FavoritesLocalDataSourceImpl dataSource;
  late FavoritesRepoImpl repo;
  late GetFavoriteChannelsUseCase getUseCase;
  late ToggleFavoriteChannelUseCase toggleUseCase;

  final sampleChannel = ChannelItemEntity(
    channel: ChannelsResponseEntity(
      id: 'aloula.eg',
      name: 'Al Oula',
      categories: ['News', 'General'],
      country: 'eg',
    ),
    logoUrl: 'https://example.com/logo.png',
  );

  final sampleChannel2 = ChannelItemEntity(
    channel: ChannelsResponseEntity(
      id: 'dmc.eg',
      name: 'DMC',
      categories: ['Entertainment'],
      country: 'eg',
    ),
    logoUrl: 'https://example.com/dmc.png',
  );

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(FavoritesLocalDataSourceImpl.boxName)) {
      await Hive.box<dynamic>(FavoritesLocalDataSourceImpl.boxName).clear();
    }
    dataSource = FavoritesLocalDataSourceImpl();
    repo = FavoritesRepoImpl(dataSource);
    getUseCase = GetFavoriteChannelsUseCase(repo);
    toggleUseCase = ToggleFavoriteChannelUseCase(repo);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('FavoriteChannelDto Tests', () {
    test('should correctly serialize and deserialize to/from JSON and Entity', () {
      final dto = FavoriteChannelDto.fromEntity(sampleChannel);
      expect(dto.id, 'aloula.eg');
      expect(dto.name, 'Al Oula');
      expect(dto.logoUrl, 'https://example.com/logo.png');

      final json = dto.toJson();
      final fromJson = FavoriteChannelDto.fromJson(json);
      final entity = fromJson.toEntity();

      expect(entity.channel.id, sampleChannel.channel.id);
      expect(entity.channel.name, sampleChannel.channel.name);
      expect(entity.logoUrl, sampleChannel.logoUrl);
      expect(entity.channel.categories, sampleChannel.channel.categories);
    });
  });

  group('FavoritesLocalDataSource & Repo Tests', () {
    test('should save, retrieve, check and remove favorite channels in Hive', () async {
      expect(await dataSource.isFavoriteChannel('aloula.eg'), isFalse);

      await dataSource.saveFavoriteChannel(FavoriteChannelDto.fromEntity(sampleChannel));
      expect(await dataSource.isFavoriteChannel('aloula.eg'), isTrue);

      final list = await dataSource.getFavoriteChannels();
      expect(list.length, 1);
      expect(list.first.id, 'aloula.eg');

      await dataSource.removeFavoriteChannel('aloula.eg');
      expect(await dataSource.isFavoriteChannel('aloula.eg'), isFalse);
    });

    test('repo toggleFavoriteChannel should add when not present and remove when present', () async {
      final added = await repo.toggleFavoriteChannel(sampleChannel);
      expect(added, isTrue);
      expect(await repo.isFavoriteChannel('aloula.eg'), isTrue);

      final channels = await repo.getFavoriteChannels();
      expect(channels.length, 1);
      expect(channels.first.channel.id, 'aloula.eg');

      final removed = await repo.toggleFavoriteChannel(sampleChannel);
      expect(removed, isFalse);
      expect(await repo.isFavoriteChannel('aloula.eg'), isFalse);
    });
  });

  group('FavoritesCubit Tests', () {
    test('should load favorites, toggle favorites, search and filter by category', () async {
      final cubit = FavoritesCubit(
        getFavoriteChannelsUseCase: getUseCase,
        toggleFavoriteChannelUseCase: toggleUseCase,
      );

      await cubit.loadFavorites();
      expect(cubit.state, isA<FavoritesLoaded>());
      var state = cubit.state as FavoritesLoaded;
      expect(state.allFavorites, isEmpty);

      // Toggle first channel
      final isNowFav = await cubit.toggleFavorite(sampleChannel);
      expect(isNowFav, isTrue);
      expect(cubit.isChannelFavorite('aloula.eg'), isTrue);

      state = cubit.state as FavoritesLoaded;
      expect(state.allFavorites.length, 1);
      expect(state.categories, containsAll(['All', 'News', 'General']));

      // Toggle second channel
      await cubit.toggleFavorite(sampleChannel2);
      state = cubit.state as FavoritesLoaded;
      expect(state.allFavorites.length, 2);

      // Filter by category
      cubit.filterByCategory('Entertainment');
      state = cubit.state as FavoritesLoaded;
      expect(state.selectedCategory, 'Entertainment');
      expect(state.filteredFavorites.length, 1);
      expect(state.filteredFavorites.first.channel.id, 'dmc.eg');

      // Reset filter
      cubit.filterByCategory('All');
      state = cubit.state as FavoritesLoaded;
      expect(state.filteredFavorites.length, 2);

      // Remove channel
      await cubit.toggleFavorite(sampleChannel);
      expect(cubit.isChannelFavorite('aloula.eg'), isFalse);
      state = cubit.state as FavoritesLoaded;
      expect(state.allFavorites.length, 1);
      expect(state.allFavorites.first.channel.id, 'dmc.eg');

      await cubit.close();
    });
  });
}
