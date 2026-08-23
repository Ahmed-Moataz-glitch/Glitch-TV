part of 'home_cubit.dart';

sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeSuccess extends HomeState {
  final List<ChannelItemEntity> allItems;
  final List<ChannelItemEntity> filteredItems;
  final List<ChannelItemEntity> featuredItems;
  final List<String> categories;
  final String selectedCategory;
  final List<RadioStationEntity> radioStations;
  final List<PodcastEntity> podcasts;

  HomeSuccess({
    required this.allItems,
    required this.filteredItems,
    required this.featuredItems,
    required this.categories,
    required this.selectedCategory,
    this.radioStations = const [],
    this.podcasts = const [],
  });
}

final class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}
