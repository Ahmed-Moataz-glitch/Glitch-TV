import 'package:flutter/material.dart';
import 'package:glitch_tv/core/view/widgets/app_section.dart';
import 'package:glitch_tv/features/channel_details/presentation/view/pages/channel_details_page.dart';
import 'package:glitch_tv/features/channel_details/presentation/view/pages/channel_stream_page.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';
import 'package:glitch_tv/features/home/presentation/view/pages/podcast_player_page.dart';
import 'package:glitch_tv/features/home/presentation/view/pages/radio_player_page.dart';
import 'package:go_router/go_router.dart';

import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';
import 'package:glitch_tv/features/podcast_details/presentation/view/pages/podcast_details_page.dart';

abstract class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String homePath = '/home';
  static const String homeName = 'home';
  static const String favoritesPath = '/favorites';
  static const String favoritesName = 'favorites';
  static const String settingsPath = '/settings';
  static const String settingsName = 'settings';
  static const String channelDetailsPath = '/channel-details';
  static const String channelDetailsName = 'channel-details';
  static const String watchStreamPath = '/watch-stream';
  static const String watchStreamName = 'watch-stream';
  static const String radioPlayerPath = '/radio-player';
  static const String radioPlayerName = 'radio-player';
  static const String podcastDetailsPath = '/podcast-details';
  static const String podcastDetailsName = 'podcast-details';
  static const String podcastPlayerPath = '/podcast-player';
  static const String podcastPlayerName = 'podcast-player';
  static late final GoRouter router;

  static void initializeRouter() {
    router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: homePath,
      debugLogDiagnostics: true,
      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
      routes: [
        GoRoute(
          path: homePath,
          name: homeName,
          builder: (context, state) => const AppSection(initialIndex: 0),
        ),
        GoRoute(
          path: favoritesPath,
          name: favoritesName,
          builder: (context, state) => const AppSection(initialIndex: 1),
        ),
        GoRoute(
          path: settingsPath,
          name: settingsName,
          builder: (context, state) => const AppSection(initialIndex: 2),
        ),
        GoRoute(
          path: channelDetailsPath,
          name: channelDetailsName,
          builder: (context, state) {
            if (state.extra is ChannelItemEntity) {
              return ChannelDetailsPage(channelItem: state.extra as ChannelItemEntity);
            }
            return Scaffold(
              appBar: AppBar(title: const Text('Channel Details')),
              body: const Center(child: Text('Channel information not available')),
            );
          },
        ),
        GoRoute(
          path: watchStreamPath,
          name: watchStreamName,
          builder: (context, state) {
            if (state.extra is ChannelItemEntity) {
              return ChannelStreamPage(channelItem: state.extra as ChannelItemEntity);
            }
            return Scaffold(
              appBar: AppBar(title: const Text('Watch Stream')),
              body: const Center(child: Text('Stream information not available')),
            );
          },
        ),
        GoRoute(
          path: radioPlayerPath,
          name: radioPlayerName,
          builder: (context, state) {
            if (state.extra is Map<String, dynamic>) {
              final map = state.extra as Map<String, dynamic>;
              return RadioPlayerPage(
                station: map['station'] as RadioStationEntity,
                stationsList:
                    (map['stationsList'] as List<RadioStationEntity>?) ??
                        const [],
              );
            }
            final station = state.extra as RadioStationEntity;
            return RadioPlayerPage(station: station);
          },
        ),
        GoRoute(
          path: podcastDetailsPath,
          name: podcastDetailsName,
          builder: (context, state) {
            if (state.extra is Map<String, dynamic>) {
              final map = state.extra as Map<String, dynamic>;
              return PodcastDetailsPage(
                podcast: map['podcast'] as PodcastEntity,
                podcastsList:
                    (map['podcastsList'] as List<PodcastEntity>?) ??
                        const [],
              );
            }
            final podcast = state.extra as PodcastEntity;
            return PodcastDetailsPage(podcast: podcast);
          },
        ),
        GoRoute(
          path: podcastPlayerPath,
          name: podcastPlayerName,
          builder: (context, state) {
            if (state.extra is Map<String, dynamic>) {
              final map = state.extra as Map<String, dynamic>;
              return PodcastPlayerPage(
                podcast: map['podcast'] as PodcastEntity,
                podcastsList:
                    (map['podcastsList'] as List<PodcastEntity>?) ??
                        const [],
                initialEpisodes: (map['initialEpisodes']
                        as List<PodcastEpisodeEntity>?) ??
                    const [],
                initialEpisodeIndex:
                    (map['initialEpisodeIndex'] as num?)?.toInt() ?? 0,
              );
            }
            final podcast = state.extra as PodcastEntity;
            return PodcastPlayerPage(podcast: podcast);
          },
        ),
      ],
    );
  }
}
