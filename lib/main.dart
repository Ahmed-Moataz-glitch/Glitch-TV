import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_constants.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
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

void main() {
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

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(411, 869),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [BlocProvider(create: (context) => _homeCubit)],
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: AppConstants.appName,
            theme: ThemeData(
              scaffoldBackgroundColor: AppColors.scaffoldBackground,
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            ),
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}
