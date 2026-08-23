part of 'favorites_cubit.dart';

sealed class FavoritesState {}

final class FavoritesInitial extends FavoritesState {}

final class FavoritesLoading extends FavoritesState {}

final class FavoritesLoaded extends FavoritesState {
  final List<ChannelItemEntity> allFavorites;
  final List<ChannelItemEntity> filteredFavorites;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;

  FavoritesLoaded({
    required this.allFavorites,
    required this.filteredFavorites,
    required this.categories,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  FavoritesLoaded copyWith({
    List<ChannelItemEntity>? allFavorites,
    List<ChannelItemEntity>? filteredFavorites,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return FavoritesLoaded(
      allFavorites: allFavorites ?? this.allFavorites,
      filteredFavorites: filteredFavorites ?? this.filteredFavorites,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final class FavoritesError extends FavoritesState {
  final String message;

  FavoritesError(this.message);
}
