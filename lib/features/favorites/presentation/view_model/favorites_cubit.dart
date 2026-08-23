import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glitch_tv/features/favorites/domain/use_case/get_favorite_channels_use_case.dart';
import 'package:glitch_tv/features/favorites/domain/use_case/toggle_favorite_channel_use_case.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';

part 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final GetFavoriteChannelsUseCase getFavoriteChannelsUseCase;
  final ToggleFavoriteChannelUseCase toggleFavoriteChannelUseCase;

  List<ChannelItemEntity> _allFavorites = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  Timer? _searchDebounce;

  FavoritesCubit({
    required this.getFavoriteChannelsUseCase,
    required this.toggleFavoriteChannelUseCase,
  }) : super(FavoritesInitial());

  List<ChannelItemEntity> get allFavorites => List.unmodifiable(_allFavorites);

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> loadFavorites() async {
    emit(FavoritesLoading());
    try {
      final channels = await getFavoriteChannelsUseCase.call();
      _allFavorites = channels;
      _applyFilters();
    } catch (e) {
      emit(FavoritesError('Failed to load favorites: ${e.toString()}'));
    }
  }

  bool isChannelFavorite(String channelId) {
    final lowerId = channelId.toLowerCase().trim();
    return _allFavorites.any((item) => item.channel.id.toLowerCase().trim() == lowerId);
  }

  Future<bool> toggleFavorite(ChannelItemEntity channel) async {
    try {
      final isNowFav = await toggleFavoriteChannelUseCase.call(channel);
      final lowerId = channel.channel.id.toLowerCase().trim();
      if (isNowFav) {
        if (!_allFavorites.any((item) => item.channel.id.toLowerCase().trim() == lowerId)) {
          _allFavorites.add(channel);
        }
      } else {
        _allFavorites.removeWhere((item) => item.channel.id.toLowerCase().trim() == lowerId);
      }
      _applyFilters();
      return isNowFav;
    } catch (e) {
      return isChannelFavorite(channel.channel.id);
    }
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void searchFavorites(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      _searchQuery = query.trim().toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    final Set<String> categoriesSet = {'All'};
    for (var item in _allFavorites) {
      for (var cat in item.channel.categories) {
        if (cat.isNotEmpty) {
          final formattedCat = cat[0].toUpperCase() + cat.substring(1);
          categoriesSet.add(formattedCat);
        }
      }
    }

    final categoriesList = categoriesSet.toList()
      ..sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        return a.compareTo(b);
      });

    if (!categoriesSet.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }

    List<ChannelItemEntity> filtered = List.from(_allFavorites);

    if (_selectedCategory != 'All') {
      filtered = filtered.where((item) {
        final itemCats = item.channel.categories
            .map((c) => c.isEmpty ? '' : c[0].toUpperCase() + c.substring(1))
            .toList();
        return itemCats.contains(_selectedCategory);
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = item.channel.name.toLowerCase();
        final id = item.channel.id.toLowerCase();
        return name.contains(_searchQuery) || id.contains(_searchQuery);
      }).toList();
    }

    emit(FavoritesLoaded(
      allFavorites: List.unmodifiable(_allFavorites),
      filteredFavorites: filtered,
      categories: categoriesList,
      selectedCategory: _selectedCategory,
      searchQuery: _searchQuery,
    ));
  }
}
