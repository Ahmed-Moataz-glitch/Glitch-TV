import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/home/presentation/view_model/home_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class PodcastTabView extends StatefulWidget {
  final HomeCubit homeCubit;
  const PodcastTabView({super.key, required this.homeCubit});

  @override
  State<PodcastTabView> createState() => _PodcastTabViewState();
}

class _PodcastTabViewState extends State<PodcastTabView>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _podcastSearchController;
  String _selectedPodcastCategory = 'All';

  @override
  bool get wantKeepAlive => true;

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
  void initState() {
    super.initState();
    _podcastSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _podcastSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final l10n = context.l10n;

    return BlocBuilder<HomeCubit, HomeState>(
      bloc: widget.homeCubit,
      builder: (context, state) {
        final podcastsList = (state is HomeSuccess)
            ? state.podcasts
            : <PodcastEntity>[];

        return StatefulBuilder(
          builder: (context, setPodcastState) {
            final query = _podcastSearchController.text.trim().toLowerCase();
            final filtered = podcastsList.where((podcast) {
              final matchesCategory =
                  _selectedPodcastCategory == 'All' ||
                  podcast.category.toLowerCase() ==
                      _selectedPodcastCategory.toLowerCase();
              final matchesQuery =
                  query.isEmpty ||
                  podcast.name.toLowerCase().contains(query) ||
                  podcast.host.toLowerCase().contains(query);
              return matchesCategory && matchesQuery;
            }).toList();

            final dynamicCategories = <String>{'All'};
            for (var p in podcastsList) {
              if (p.category.isNotEmpty) {
                dynamicCategories.add(p.category);
              }
            }
            final categoriesList = dynamicCategories.toList();

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
                        // Search Input
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
                            controller: _podcastSearchController,
                            onChanged: (_) => setPodcastState(() {}),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14.sp,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  l10n?.searchPodcasts ??
                                  'Search Podcasts & Shows...',
                              hintStyle: TextStyle(
                                color: context.textSecondary.withValues(alpha: 0.7),
                                fontSize: 14.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.podcasts_rounded,
                                color: AppColors.primaryLight,
                                size: 20.sp,
                              ),
                              suffixIcon: _podcastSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: context.textSecondary,
                                        size: 18.sp,
                                      ),
                                      onPressed: () {
                                        _podcastSearchController.clear();
                                        setPodcastState(() {});
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

                        // Category Selector Chips
                        SizedBox(
                          height: 38.h,
                          child: ListView.separated(
                            physics: const ClampingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            itemCount: categoriesList.length,
                            separatorBuilder: (_, __) => SizedBox(width: 8.w),
                            itemBuilder: (context, index) {
                              final cat = categoriesList[index];
                              final isSelected = cat == _selectedPodcastCategory;
                              final localizedCat = _getLocalizedCategory(
                                context,
                                cat,
                              );

                              return ChoiceChip(
                                label: Text(localizedCat),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setPodcastState(() {
                                    _selectedPodcastCategory = cat;
                                  });
                                },
                                selectedColor: AppColors.primary,
                                backgroundColor: context.cardBg,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : context.textPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (context.isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.black.withValues(alpha: 0.06)),
                                  ),
                                ),
                                showCheckmark: false,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Podcast Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n?.trendingPodcasts ?? 'Trending Podcasts',
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
                                '${filtered.length}',
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
                if (state is HomeLoading)
                  SliverToBoxAdapter(child: _buildLoadingScreen())
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyView(
                      l10n?.noPodcastsFound ?? 'No podcasts found',
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final podcast = filtered[index];
                        return InkWell(
                          onTap: () {
                            context.push(
                              AppRouter.podcastDetailsPath,
                              extra: {
                                'podcast': podcast,
                                'podcastsList': filtered,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: context.isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 80.w,
                                  height: 80.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(30),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14.r),
                                    child: podcast.artworkUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: podcast.artworkUrl,
                                            memCacheWidth: (80 * devicePixelRatio).toInt(),
                                            memCacheHeight: (80 * devicePixelRatio).toInt(),
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Icon(
                                              Icons.mic_external_on_rounded,
                                              color: AppColors.primaryLight,
                                              size: 28.sp,
                                            ),
                                          )
                                        : Icon(
                                            Icons.mic_external_on_rounded,
                                            color: AppColors.primaryLight,
                                            size: 28.sp,
                                          ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    spacing: 6.h,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        podcast.name,
                                        style: TextStyle(
                                          color: context.textPrimary,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (podcast.host.isNotEmpty) ...[
                                        Text(
                                          'Host: ${podcast.host}',
                                          style: TextStyle(
                                            color: context.textSecondary,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ],
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.category_rounded,
                                            size: 14.sp,
                                            color: AppColors.primaryLight,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            podcast.category.isNotEmpty
                                                ? _getLocalizedCategory(
                                                    context,
                                                    podcast.category,
                                                  )
                                                : (l10n?.podcasts ??
                                                      'Podcasts'),
                                            style: TextStyle(
                                              color: context.textPrimary,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
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