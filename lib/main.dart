import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_constants.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/l10n/app_localizations.dart';
import 'package:glitch_tv/features/favorites/data/repo/data_source/favorites_local_data_source_impl.dart';
import 'package:glitch_tv/features/favorites/data/repo/repo/favorites_repo_impl.dart';
import 'package:glitch_tv/features/favorites/domain/repo/data_source/favorites_local_data_source.dart';
import 'package:glitch_tv/features/favorites/domain/repo/repo/favorites_repo.dart';
import 'package:glitch_tv/features/favorites/domain/use_case/get_favorite_channels_use_case.dart';
import 'package:glitch_tv/features/favorites/domain/use_case/toggle_favorite_channel_use_case.dart';
import 'package:glitch_tv/features/favorites/presentation/view_model/favorites_cubit.dart';
import 'package:glitch_tv/features/home/data/api/home_api.dart';
import 'package:glitch_tv/features/home/data/repo/data_source/home_data_source_impl.dart';
import 'package:glitch_tv/features/home/data/repo/repo/home_repo_impl.dart';
import 'package:glitch_tv/features/home/domain/repo/data_source/home_data_source.dart';
import 'package:glitch_tv/features/home/domain/repo/repo/home_repo.dart';
import 'package:glitch_tv/features/home/domain/use_case/fetch_channels_use_case.dart';
import 'package:glitch_tv/features/home/domain/use_case/fetch_logos_use_case.dart';
import 'package:glitch_tv/features/home/domain/use_case/fetch_podcasts_use_case.dart';
import 'package:glitch_tv/features/home/domain/use_case/fetch_radio_stations_use_case.dart';
import 'package:glitch_tv/features/home/presentation/view_model/home_cubit.dart';
import 'package:glitch_tv/features/settings/data/repo/data_source/settings_local_data_source_impl.dart';
import 'package:glitch_tv/features/settings/domain/repo/data_source/settings_local_data_source.dart';
import 'package:glitch_tv/features/settings/presentation/view_model/settings_cubit.dart';
import 'package:glitch_tv/features/settings/presentation/view_model/settings_state.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.glitch_tv.channel.audio',
    androidNotificationChannelName: 'Glitch TV Radio Playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );
  await Hive.initFlutter();
  AppRouter.initializeRouter();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final HomeCubit _homeCubit;
  late final FavoritesCubit _favoritesCubit;
  late final SettingsCubit _settingsCubit;

  @override
  void initState() {
    super.initState();
    // Home Cubit Setup
    HomeApi homeApi = HomeApi();
    HomeDataSource homeDataSource = HomeDataSourceImpl(homeApi);
    HomeRepo homeRepo = HomeRepoImpl(homeDataSource);
    FetchChannelsUseCase fetchChannelsUseCase = FetchChannelsUseCase(homeRepo);
    FetchLogosUseCase fetchLogosUseCase = FetchLogosUseCase(homeRepo);
    FetchRadioStationsUseCase fetchRadioStationsUseCase =
        FetchRadioStationsUseCase(homeRepo);
    FetchPodcastsUseCase fetchPodcastsUseCase =
        FetchPodcastsUseCase(homeRepo);
    _homeCubit = HomeCubit(
      fetchLogosUseCase: fetchLogosUseCase,
      fetchChannelsUseCase: fetchChannelsUseCase,
      fetchRadioStationsUseCase: fetchRadioStationsUseCase,
      fetchPodcastsUseCase: fetchPodcastsUseCase,
    );

    // Favorites Cubit Setup
    FavoritesLocalDataSource favoritesLocalDataSource =
        FavoritesLocalDataSourceImpl();
    FavoritesRepo favoritesRepo =
        FavoritesRepoImpl(favoritesLocalDataSource);
    GetFavoriteChannelsUseCase getFavoriteChannelsUseCase =
        GetFavoriteChannelsUseCase(favoritesRepo);
    ToggleFavoriteChannelUseCase toggleFavoriteChannelUseCase =
        ToggleFavoriteChannelUseCase(favoritesRepo);
    _favoritesCubit = FavoritesCubit(
      getFavoriteChannelsUseCase: getFavoriteChannelsUseCase,
      toggleFavoriteChannelUseCase: toggleFavoriteChannelUseCase,
    )..loadFavorites();

    // Settings Cubit Setup
    SettingsLocalDataSource settingsLocalDataSource =
        SettingsLocalDataSourceImpl();
    _settingsCubit = SettingsCubit(
      localDataSource: settingsLocalDataSource,
    )..loadSettings();
  }

  @override
  void dispose() {
    _homeCubit.close();
    _favoritesCubit.close();
    _settingsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(411, 869),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _homeCubit),
            BlocProvider.value(value: _favoritesCubit),
            BlocProvider.value(value: _settingsCubit),
          ],
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: AppConstants.appName,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: settingsState.themeMode,
                locale: settingsState.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                routerConfig: AppRouter.router,
              );
            },
          ),
        );
      },
    );
  }
}
