import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/category_selector.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/channel_card.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/featured_swiper.dart';
import 'package:glitch_tv/features/home/presentation/view_model/home_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';

class TvTabView extends StatefulWidget {
  final HomeCubit homeCubit;
  const TvTabView({super.key, required this.homeCubit});

  @override
  State<TvTabView> createState() => _TvTabViewState();
}

class _TvTabViewState extends State<TvTabView>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _tvSearchController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tvSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _tvSearchController.dispose();
    super.dispose();
  }

  String _getLocalizedCategory(BuildContext context, String category) {
    final l10n = context.l10n;
    if (l10n == null) return category;
    switch (category) {
      case 'All':
        return l10n.all;
      case 'Quran':
        return l10n.categoryQuran;
      case 'Music':
        return l10n.categoryMusic;
      case 'News':
        return l10n.categoryNews;
      case 'Culture':
        return l10n.categoryCulture;
      case 'Classics':
        return l10n.categoryClassics;
      case 'Technology':
        return l10n.categoryTechnology;
      case 'Business':
        return l10n.categoryBusiness;
      case 'Stories':
        return l10n.categoryStories;
      case 'Self Development':
        return l10n.categorySelfDev;
      case 'Comedy':
        return l10n.categoryComedy;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: () async {
        await widget.homeCubit.loadData(forceRefresh: true);
      },
      color: AppColors.primaryLight,
      backgroundColor: context.cardBg,
      child: BlocConsumer<HomeCubit, HomeState>(
        bloc: widget.homeCubit,
        listener: (context, state) {
          if (state is HomeError) {
            AppToast.showToast(
              context: context,
              title: l10n?.error ?? 'Error',
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
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(
                  decelerationRate: ScrollDecelerationRate.fast,
                ),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar Input
                        Container(
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: context.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: TextField(
                            onTapOutside: (_) => FocusScope.of(context).unfocus(),
                            controller: _tvSearchController,
                            onChanged: (value) {
                              widget.homeCubit.searchChannels(value);
                            },
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14.sp,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  l10n?.searchTvChannels ?? 'Search TV channels...',
                              hintStyle: TextStyle(
                                color: context.textSecondary.withValues(alpha: 0.7),
                                fontSize: 14.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppColors.primaryLight,
                                size: 20.sp,
                              ),
                              suffixIcon: _tvSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: context.textSecondary,
                                        size: 18.sp,
                                      ),
                                      onPressed: () {
                                        _tvSearchController.clear();
                                        widget.homeCubit.searchChannels('');
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
                              widget.homeCubit.filterByCategory(category);
                            },
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // Featured Carousel Swiper
                        if (_tvSearchController.text.isEmpty &&
                            state.featuredItems.isNotEmpty &&
                            state.selectedCategory == 'All') ...[
                          Text(
                            l10n?.featuredChannels ?? 'Featured Channels',
                            style: TextStyle(
                              color: context.textPrimary,
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
                                  ? (l10n?.allChannels ?? 'All Channels')
                                  : '${_getLocalizedCategory(context, state.selectedCategory)} (${state.filteredItems.length})',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 18.sp,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '${state.filteredItems.length}',
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
                if (state.filteredItems.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyView(
                      l10n?.noChannelsFound ?? 'No TV channels found',
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
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
    );
  }

  Widget _buildLoadingScreen() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: context.cardBg,
            highlightColor: AppColors.primary.withAlpha(40),
            child: Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Shimmer.fromColors(
            baseColor: context.cardBg,
            highlightColor: AppColors.primary.withAlpha(40),
            child: Container(
              width: double.infinity,
              height: 160.h,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
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
                  baseColor: context.cardBg,
                  highlightColor: AppColors.primary.withAlpha(40),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
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
    final l10n = context.l10n;

    return Center(
      child: SingleChildScrollView(
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
              l10n?.error ?? 'Error',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 13.sp),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => widget.homeCubit.loadData(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n?.retry ?? 'Retry'),
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

  Widget _buildEmptyView(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 32.w),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64.sp,
            color: context.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Try searching with a different keyword or category',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
