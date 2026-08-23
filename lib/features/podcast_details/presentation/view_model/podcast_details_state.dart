import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';

sealed class PodcastDetailsState {}

class PodcastDetailsInitial extends PodcastDetailsState {}

class PodcastDetailsLoading extends PodcastDetailsState {}

class PodcastDetailsSuccess extends PodcastDetailsState {
  final PodcastEntity podcast;
  final List<PodcastEpisodeEntity> allEpisodes;
  final List<PodcastEpisodeEntity> filteredEpisodes;
  final String searchQuery;
  final bool isNewestFirst;

  PodcastDetailsSuccess({
    required this.podcast,
    required this.allEpisodes,
    required this.filteredEpisodes,
    this.searchQuery = '',
    this.isNewestFirst = true,
  });

  PodcastDetailsSuccess copyWith({
    PodcastEntity? podcast,
    List<PodcastEpisodeEntity>? allEpisodes,
    List<PodcastEpisodeEntity>? filteredEpisodes,
    String? searchQuery,
    bool? isNewestFirst,
  }) {
    return PodcastDetailsSuccess(
      podcast: podcast ?? this.podcast,
      allEpisodes: allEpisodes ?? this.allEpisodes,
      filteredEpisodes: filteredEpisodes ?? this.filteredEpisodes,
      searchQuery: searchQuery ?? this.searchQuery,
      isNewestFirst: isNewestFirst ?? this.isNewestFirst,
    );
  }
}

class PodcastDetailsError extends PodcastDetailsState {
  final String message;

  PodcastDetailsError(this.message);
}
