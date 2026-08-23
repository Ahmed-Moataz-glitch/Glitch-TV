import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';
import 'package:glitch_tv/features/podcast_details/domain/use_case/fetch_podcast_episodes_use_case.dart';
import 'package:glitch_tv/features/podcast_details/presentation/view_model/podcast_details_state.dart';

class PodcastDetailsCubit extends Cubit<PodcastDetailsState> {
  final FetchPodcastEpisodesUseCase fetchPodcastEpisodesUseCase;
  final PodcastEntity podcast;

  List<PodcastEpisodeEntity> _allEpisodes = [];
  String _searchQuery = '';
  bool _isNewestFirst = true;
  Timer? _searchDebounce;

  PodcastDetailsCubit({
    required this.fetchPodcastEpisodesUseCase,
    required this.podcast,
  }) : super(PodcastDetailsInitial());

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> loadEpisodes({bool forceRefresh = false}) async {
    emit(PodcastDetailsLoading());

    final result = await fetchPodcastEpisodesUseCase.call(
      feedUrl: podcast.feedUrl,
      fallbackArtwork: podcast.artworkUrl,
      forceRefresh: forceRefresh,
    );

    switch (result) {
      case ApiSuccess<List<PodcastEpisodeEntity>>():
        _allEpisodes = result.data ?? [];
        _applyFiltersAndEmit();
        break;
      case ApiError<List<PodcastEpisodeEntity>>():
        emit(PodcastDetailsError(result.message));
        break;
    }
  }

  void searchEpisodes(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      _searchQuery = query.trim().toLowerCase();
      _applyFiltersAndEmit();
    });
  }

  void toggleSortOrder() {
    _isNewestFirst = !_isNewestFirst;
    _applyFiltersAndEmit();
  }

  void _applyFiltersAndEmit() {
    List<PodcastEpisodeEntity> filtered = List.from(_allEpisodes);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ep) {
        final title = ep.title.toLowerCase();
        final desc = ep.description.toLowerCase();
        return title.contains(_searchQuery) || desc.contains(_searchQuery);
      }).toList();
    }

    if (!_isNewestFirst) {
      filtered = filtered.reversed.toList();
    }

    emit(PodcastDetailsSuccess(
      podcast: podcast,
      allEpisodes: _allEpisodes,
      filteredEpisodes: filtered,
      searchQuery: _searchQuery,
      isNewestFirst: _isNewestFirst,
    ));
  }
}
