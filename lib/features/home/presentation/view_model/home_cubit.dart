import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/home/data/models/channels_model.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';
import 'package:glitch_tv/features/home/domain/use_case/fetch_channels_use_case.dart';
import 'package:glitch_tv/features/home/domain/use_case/fetch_logos_use_case.dart';
import 'package:glitch_tv/features/home/domain/use_case/fetch_podcasts_use_case.dart';
import 'package:glitch_tv/features/channel_details/data/api/channel_details_api.dart';
import 'package:glitch_tv/features/home/domain/use_case/fetch_radio_stations_use_case.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final FetchLogosUseCase fetchLogosUseCase;
  final FetchChannelsUseCase fetchChannelsUseCase;
  final FetchRadioStationsUseCase fetchRadioStationsUseCase;
  final FetchPodcastsUseCase fetchPodcastsUseCase;

  List<ChannelItemEntity> _allItemEntities = [];
  List<ChannelItemEntity> _featuredItemEntities = [];
  List<RadioStationEntity> _radioStations = [];
  List<PodcastEntity> _podcasts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  Timer? _searchDebounce;

  HomeCubit({
    required this.fetchLogosUseCase,
    required this.fetchChannelsUseCase,
    required this.fetchRadioStationsUseCase,
    required this.fetchPodcastsUseCase,
  }) : super(HomeInitial());

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> loadData() async {
    emit(HomeLoading());
    try {
      final results = await Future.wait([
        fetchLogosUseCase.call(),
        fetchChannelsUseCase.call(),
        fetchRadioStationsUseCase.call(),
        fetchPodcastsUseCase.call(),
      ]);

      final logosResult = results[0] as ApiResult<List<LogosResponseEntity>>;
      final channelsResult = results[1] as ApiResult<List<ChannelsResponseEntity>>;
      final radioResult = results[2] as ApiResult<List<RadioStationEntity>>;
      final podcastsResult = results[3] as ApiResult<List<PodcastEntity>>;

      List<LogosResponseEntity> logosList = [];
      List<ChannelsResponseEntity> channelsList = [];

      if (logosResult is ApiSuccess<List<LogosResponseEntity>>) {
        logosList = logosResult.data ?? [];
      } else if (logosResult is ApiError<List<LogosResponseEntity>>) {
        emit(HomeError(logosResult.message));
        return;
      }

      if (channelsResult is ApiSuccess<List<ChannelsResponseEntity>>) {
        channelsList = channelsResult.data ?? [];
      }

      if (radioResult is ApiSuccess<List<RadioStationEntity>>) {
        _radioStations = radioResult.data ?? [];
      }

      if (podcastsResult is ApiSuccess<List<PodcastEntity>>) {
        _podcasts = podcastsResult.data ?? [];
      }

      // Build channel lookup map by lowercased ID
      final Map<String, ChannelsResponseEntity> channelMap = {
        for (var ch in channelsList) ch.id.toLowerCase(): ch
      };

      // Build logo lookup map by lowercased channel ID
      final Map<String, LogosResponseEntity> logoMap = {};
      for (var logo in logosList) {
        if (logo.inUse && logo.url.isNotEmpty) {
          logoMap.putIfAbsent(logo.channel.toLowerCase(), () => logo);
        }
      }

      final Set<String> categoriesSet = {'All'};
      final List<ChannelItemEntity> itemEntities = [];
      final Set<String> processedChannels = {};

      // Filter specifically for channel IDs listed in channels_model.dart
      for (var targetId in channels) {
        final lowerTargetId = targetId.toLowerCase();
        if (processedChannels.contains(lowerTargetId)) continue;

        final logo = logoMap[lowerTargetId];
        if (logo == null) continue;

        processedChannels.add(lowerTargetId);

        final channelObj = channelMap[lowerTargetId];
        
        if (channelObj != null && (channelObj.isNsfw || channelObj.closed.isNotEmpty)) {
          continue;
        }

        final channel = channelObj ??
            ChannelsResponseEntity(
              id: targetId,
              name: _formatChannelName(targetId),
              altNames: const [],
              network: '',
              owners: const [],
              country: '',
              categories: const ['General'],
              isNsfw: false,
              launched: '',
              closed: '',
              replacedBy: '',
              website: '',
            );

        for (var cat in channel.categories) {
          if (cat.isNotEmpty) {
            final formattedCat = cat[0].toUpperCase() + cat.substring(1);
            categoriesSet.add(formattedCat);
          }
        }

        itemEntities.add(ChannelItemEntity(
          channel: channel,
          logoUrl: logo.url,
        ));
      }

      _allItemEntities = itemEntities;
      _categories = categoriesSet.toList()..sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        return a.compareTo(b);
      });

      _featuredItemEntities = List.from(_allItemEntities);

      _applyFilters();

      // Pre-warm channel streams cache in background for instant playback across the app
      ChannelDetailsApi().fetchStreams();
    } catch (e) {
      emit(HomeError('Failed to load channels: ${e.toString()}'));
    }
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void searchChannels(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      _searchQuery = query.trim().toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<ChannelItemEntity> filtered = _allItemEntities;

    // Filter by Category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((item) {
        final itemCats = item.channel.categories
            .map((c) => c.isEmpty ? '' : c[0].toUpperCase() + c.substring(1))
            .toList();
        return itemCats.contains(_selectedCategory);
      }).toList();
    }

    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = item.channel.name.toLowerCase();
        final id = item.channel.id.toLowerCase();
        return name.contains(_searchQuery) || id.contains(_searchQuery);
      }).toList();
    }

    emit(HomeSuccess(
      allItems: _allItemEntities,
      filteredItems: filtered,
      featuredItems: _featuredItemEntities,
      categories: _categories,
      selectedCategory: _selectedCategory,
      radioStations: _radioStations,
      podcasts: _podcasts,
    ));
  }

  String _formatChannelName(String channelId) {
    final parts = channelId.split('.');
    if (parts.isNotEmpty) {
      return parts.first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ').trim();
    }
    return channelId;
  }
}
