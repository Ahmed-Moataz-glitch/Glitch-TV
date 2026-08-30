import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_assets.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/podcast_tab_view.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/radio_tab_view.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/tv_tab_view.dart';
import 'package:glitch_tv/features/home/presentation/view_model/home_cubit.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final HomeCubit _homeCubit;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _homeCubit = context.read<HomeCubit>();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_homeCubit.state is HomeInitial) {
        await _homeCubit.loadData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header & TabBar
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              child: Column(
                children: [
                  _buildTopHeader(),
                  SizedBox(height: 20.h),
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: context.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 1.0,
                      ),
                    ),
                    padding: EdgeInsets.all(4.r),
                    child: TabBar(
                      controller: _tabController,
                      physics: const ClampingScrollPhysics(),
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: context.textPrimary,
                      labelStyle: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      tabs: [
                        Tab(
                          height: 38.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.live_tv_rounded, size: 18),
                              SizedBox(width: 6.w),
                              Text(l10n?.tv ?? 'TV'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 38.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.radio_rounded, size: 18),
                              SizedBox(width: 6.w),
                              Text(l10n?.radio ?? 'Radio'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 38.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.podcasts_rounded, size: 18),
                              SizedBox(width: 6.w),
                              Text(l10n?.podcasts ?? 'Podcasts'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            // TabBarView Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const ClampingScrollPhysics(),
                children: [
                  TvTabView(homeCubit: _homeCubit),
                  RadioTabView(homeCubit: _homeCubit),
                  PodcastTabView(homeCubit: _homeCubit),
                ],
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final l10n = context.l10n;

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 42.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppColors.textPrimary.withAlpha(220)
                    : AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            Lottie.asset(AppAssets.glitchTvLottie, width: 64.w, height: 64.h),
          ],
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GLITCH TV',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              l10n?.liveMediaStreams ?? 'Live Media & Streams',
              style: TextStyle(color: context.textSecondary, fontSize: 11.sp),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: context.cardBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: context.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(
            Icons.graphic_eq_rounded,
            color: AppColors.primaryLight,
            size: 20.sp,
          ),
        ),
      ],
    );
  }
}
