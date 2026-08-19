import 'package:flutter/material.dart';
import 'package:glitch_tv/core/view/widgets/app_section.dart';
import 'package:glitch_tv/features/channel_details/presentation/view/pages/channel_details_page.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:go_router/go_router.dart';

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
            final item = state.extra as ChannelItemEntity;
            return ChannelDetailsPage(channelItem: item);
          },
        ),
      ],
    );
  }
}
