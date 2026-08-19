import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_assets.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/category_selector.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/channel_card.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/featured_swiper.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/features/home/presentation/view_model/home_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeCubit _homeCubit;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _homeCubit = context.read<HomeCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_homeCubit.state is HomeInitial) {
        _homeCubit.loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _homeCubit.loadData();
          },
          color: AppColors.primaryLight,
          backgroundColor: AppColors.card,
          child: BlocConsumer<HomeCubit, HomeState>(
            bloc: _homeCubit,
            listener: (context, state) {
              if (state is HomeError) {
                AppToast.showToast(
                  context: context,
                  title: 'Error',
                  description: state.message,
                  type: ToastificationType.error,
                );
              }
            },
            builder: (context, state) {
              if (state is HomeLoading || state is HomeInitial) {
                return _buildLoadingScreen();
              }

              if (state is HomeError) {
                return _buildErrorView(state.message);
              }

              if (state is HomeSuccess) {
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header, Search, Categories & Featured Swiper
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Header
                            Row(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 42.w,
                                      height: 40.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.textPrimary.withAlpha(220),
                                        borderRadius: BorderRadius.circular(24.r),
                                        shape: BoxShape.rectangle,
                                      ),
                                    ),
                                    Lottie.asset(
                                      AppAssets.glitchTvLottie,
                                      width: 64.w,
                                      height: 64.h,
                                    ),
                                  ],
                                ),
                                SizedBox(width: 8.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GLITCH TV',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      'Live IPTV Channels',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.textSecondary.withAlpha(30),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.live_tv,
                                    color: AppColors.primaryLight,
                                    size: 20.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),

                            // Search Bar Input
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: AppColors.textSecondary.withAlpha(30),
                                ),
                              ),
                              child: TextField(
                                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                                controller: _searchController,
                                onChanged: (value) {
                                  _homeCubit.searchChannels(value);
                                },
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14.sp,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search channels...',
                                  hintStyle: TextStyle(
                                    color: AppColors.textSecondary.withAlpha(150),
                                    fontSize: 14.sp,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: AppColors.primaryLight,
                                    size: 20.sp,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear_rounded,
                                            color: AppColors.textSecondary,
                                            size: 18.sp,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _homeCubit.searchChannels('');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Category Selector
                            if (state.categories.isNotEmpty) ...[
                              CategorySelector(
                                categories: state.categories,
                                selectedCategory: state.selectedCategory,
                                onSelectCategory: (category) {
                                  _homeCubit.filterByCategory(category);
                                },
                              ),
                              SizedBox(height: 20.h),
                            ],

                            // Featured Carousel Swiper (when not searching)
                            if (_searchController.text.isEmpty &&
                                state.featuredItems.isNotEmpty &&
                                state.selectedCategory == 'All') ...[
                              Text(
                                'Featured Channels',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              FeaturedSwiper(items: state.featuredItems),
                              SizedBox(height: 24.h),
                            ],

                            // Channels Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  state.selectedCategory == 'All'
                                      ? 'All Channels'
                                      : '${state.selectedCategory} Channels',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    '${state.filteredItems.length} channels',
                                    style: TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      ),
                    ),

                    // Empty View vs Virtualized SliverGrid
                    if (state.filteredItems.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyView(),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16.h,
                            crossAxisSpacing: 16.w,
                            childAspectRatio: 1.1,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = state.filteredItems[index];
                              return ChannelCard(
                                item: item,
                                onTap: () {
                                  context.push(
                                    AppRouter.channelDetailsPath,
                                    extra: item,
                                  );
                                },
                              );
                            },
                            childCount: state.filteredItems.length,
                          ),
                        ),
                      ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Shimmer.fromColors(
                baseColor: AppColors.card,
                highlightColor: AppColors.primary.withAlpha(40),
                child: Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: AppColors.card,
                    highlightColor: AppColors.primary.withAlpha(40),
                    child: Container(
                      width: 120.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Shimmer.fromColors(
                    baseColor: AppColors.card,
                    highlightColor: AppColors.primary.withAlpha(40),
                    child: Container(
                      width: 80.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Shimmer.fromColors(
            baseColor: AppColors.card,
            highlightColor: AppColors.primary.withAlpha(40),
            child: Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Shimmer.fromColors(
            baseColor: AppColors.card,
            highlightColor: AppColors.primary.withAlpha(40),
            child: Container(
              width: double.infinity,
              height: 160.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.h,
                crossAxisSpacing: 16.w,
                childAspectRatio: 1.1,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: AppColors.card,
                  highlightColor: AppColors.primary.withAlpha(40),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64.sp,
              color: Colors.redAccent.withAlpha(180),
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to load channels',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => _homeCubit.loadData(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 32.w),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64.sp,
            color: AppColors.textSecondary.withAlpha(100),
          ),
          SizedBox(height: 12.h),
          Text(
            'No channels found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Try searching with a different keyword or category',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
