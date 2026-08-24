import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/features/favorites/presentation/view_model/favorites_cubit.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/category_selector.dart';
import 'package:glitch_tv/features/home/presentation/view/widgets/channel_card.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final favoritesCubit = context.read<FavoritesCubit>();
    if (favoritesCubit.state is FavoritesInitial) {
      favoritesCubit.loadFavorites();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<FavoritesCubit>().loadFavorites();
          },
          color: AppColors.primaryLight,
          backgroundColor: context.cardBg,
          child: BlocConsumer<FavoritesCubit, FavoritesState>(
            listener: (context, state) {
              if (state is FavoritesError) {
                AppToast.showToast(
                  context: context,
                  title: l10n?.error ?? 'Error',
                  description: state.message,
                  type: ToastificationType.error,
                );
              }
            },
            builder: (context, state) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopHeader(state),
                          SizedBox(height: 20.h),
                          if (state is FavoritesLoaded &&
                              state.allFavorites.isNotEmpty) ...[
                            _buildSearchBar(context),
                            SizedBox(height: 16.h),
                            if (state.categories.length > 1) ...[
                              CategorySelector(
                                categories: state.categories,
                                selectedCategory: state.selectedCategory,
                                onSelectCategory: (cat) {
                                  context
                                      .read<FavoritesCubit>()
                                      .filterByCategory(cat);
                                },
                              ),
                              SizedBox(height: 16.h),
                            ],
                            _buildSectionHeader(state),
                            SizedBox(height: 12.h),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (state is FavoritesLoading || state is FavoritesInitial)
                    SliverToBoxAdapter(
                      child: _buildLoadingScreen(),
                    )
                  else if (state is FavoritesLoaded)
                    if (state.allFavorites.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(
                          title: l10n?.noFavoritesYet ??
                              'No Favorite Channels Yet',
                          description: l10n?.noFavoritesDescription ??
                              'Tap the heart icon on any channel card to save it here for quick access.',
                          icon: Icons.favorite_border_rounded,
                        ),
                      )
                    else if (state.filteredFavorites.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(
                          title: l10n?.noResultsFound ?? 'No Matching Favorites',
                          description:
                              'No channels match your current search or category filter.',
                          icon: Icons.search_off_rounded,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16.h,
                            crossAxisSpacing: 16.w,
                            childAspectRatio: 1.1,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = state.filteredFavorites[index];
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
                            childCount: state.filteredFavorites.length,
                          ),
                        ),
                      )
                  else if (state is FavoritesError)
                    SliverToBoxAdapter(
                      child: _buildErrorView(context, state.message),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(FavoritesState state) {
    final count = state is FavoritesLoaded ? state.allFavorites.length : 0;
    final l10n = context.l10n;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
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
            Icons.favorite_rounded,
            color: AppColors.primaryLight,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.favorites.toUpperCase() ?? 'FAVORITES',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              l10n?.favoriteChannels ?? 'Your Saved TV Channels',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (state is FavoritesLoaded)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.primaryLight.withAlpha(50),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tv_rounded,
                  size: 14.sp,
                  color: AppColors.primaryLight,
                ),
                SizedBox(width: 6.w),
                Text(
                  '$count',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final l10n = context.l10n;

    return Container(
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
        controller: _searchController,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        onChanged: (value) {
          context.read<FavoritesCubit>().searchFavorites(value);
        },
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 14.sp,
        ),
        decoration: InputDecoration(
          hintText: l10n?.searchFavorites ?? 'Search favorite channels...',
          hintStyle: TextStyle(
            color: context.textSecondary.withValues(alpha: 0.7),
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
                    color: context.textSecondary,
                    size: 18.sp,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    context.read<FavoritesCubit>().searchFavorites('');
                    setState(() {});
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
    );
  }

  Widget _buildSectionHeader(FavoritesLoaded state) {
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          state.selectedCategory == 'All'
              ? (l10n?.favoriteChannels ?? 'All Favorite Channels')
              : state.selectedCategory,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
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
            '${state.filteredFavorites.length}',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 32.w),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: context.cardBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryLight.withAlpha(40),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 56.sp,
              color: AppColors.primaryLight.withAlpha(180),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 16.w,
          childAspectRatio: 1.1,
        ),
        itemCount: 4,
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
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 56.sp,
            color: Colors.redAccent.withAlpha(180),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n?.error ?? 'Failed to load favorites',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: () => context.read<FavoritesCubit>().loadFavorites(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n?.retry ?? 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}