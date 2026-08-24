import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/podcast_details/data/api/podcast_details_api.dart';
import 'package:glitch_tv/features/podcast_details/data/repo/data_source/podcast_details_data_source_impl.dart';
import 'package:glitch_tv/features/podcast_details/data/repo/repo/podcast_details_repo_impl.dart';
import 'package:glitch_tv/features/podcast_details/domain/repo/data_source/podcast_details_data_source.dart';
import 'package:glitch_tv/features/podcast_details/domain/repo/repo/podcast_details_repo.dart';
import 'package:glitch_tv/features/podcast_details/domain/use_case/fetch_podcast_episodes_use_case.dart';
import 'package:glitch_tv/features/podcast_details/presentation/view/widgets/podcast_episode_card.dart';
import 'package:glitch_tv/features/podcast_details/presentation/view/widgets/podcast_info_header.dart';
import 'package:glitch_tv/features/podcast_details/presentation/view_model/podcast_details_cubit.dart';
import 'package:glitch_tv/features/podcast_details/presentation/view_model/podcast_details_state.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';

class PodcastDetailsPage extends StatefulWidget {
  final PodcastEntity podcast;
  final List<PodcastEntity> podcastsList;

  const PodcastDetailsPage({
    super.key,
    required this.podcast,
    this.podcastsList = const [],
  });

  @override
  State<PodcastDetailsPage> createState() => _PodcastDetailsPageState();
}

class _PodcastDetailsPageState extends State<PodcastDetailsPage> {
  late final PodcastDetailsCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final api = PodcastDetailsApi();
    final PodcastDetailsDataSource dataSource =
        PodcastDetailsDataSourceImpl(api);
    final PodcastDetailsRepo repo = PodcastDetailsRepoImpl(dataSource);
    final useCase = FetchPodcastEpisodesUseCase(repo);

    _cubit = PodcastDetailsCubit(
      fetchPodcastEpisodesUseCase: useCase,
      podcast: widget.podcast,
    );

    _cubit.loadEpisodes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _navigateToPlayer({
    required List episodes,
    required int initialIndex,
  }) {
    context.push(
      AppRouter.podcastPlayerPath,
      extra: {
        'podcast': widget.podcast,
        'podcastsList': widget.podcastsList,
        'initialEpisodes': episodes,
        'initialEpisodeIndex': initialIndex,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: context.scaffoldBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.textPrimary,
              size: 20.sp,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            widget.podcast.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isFavorite
                    ? AppColors.primaryLight
                    : context.textSecondary,
                size: 22.sp,
              ),
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _cubit.loadEpisodes(forceRefresh: true);
            },
            color: AppColors.primaryLight,
            backgroundColor: context.cardBg,
            child: BlocConsumer<PodcastDetailsCubit, PodcastDetailsState>(
              listener: (context, state) {
                if (state is PodcastDetailsError) {
                  AppToast.showToast(
                    context: context,
                    title: l10n?.error ?? 'Error',
                    description: state.message,
                    type: ToastificationType.error,
                  );
                }
              },
              builder: (context, state) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      PodcastInfoHeader(
                        podcast: widget.podcast,
                        onPlayLatest: state is PodcastDetailsSuccess &&
                                state.allEpisodes.isNotEmpty
                            ? () {
                                _navigateToPlayer(
                                  episodes: state.allEpisodes,
                                  initialIndex: 0,
                                );
                              }
                            : null,
                      ),
                      SizedBox(height: 20.h),

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
                          onTapOutside: (_) =>
                              FocusScope.of(context).unfocus(),
                          controller: _searchController,
                          onChanged: (val) {
                            _cubit.searchEpisodes(val);
                          },
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n?.searchPodcasts ?? 'Search episodes by title or topic...',
                            hintStyle: TextStyle(
                              color: context.textSecondary.withValues(alpha: 0.6),
                              fontSize: 13.sp,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 20,
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
                                      _cubit.searchEpisodes('');
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
                      ),
                      SizedBox(height: 20.h),

                      // Episodes Section Header (Count & Sort)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.format_list_bulleted_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                l10n?.episodes ?? 'Episodes',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (state is PodcastDetailsSuccess) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: context.isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Text(
                                    '${state.filteredEpisodes.length}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (state is PodcastDetailsSuccess &&
                              state.allEpisodes.isNotEmpty)
                            InkWell(
                              onTap: () => _cubit.toggleSortOrder(),
                              borderRadius: BorderRadius.circular(10.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: AppColors.primary.withAlpha(40),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      state.isNewestFirst
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: AppColors.primaryLight,
                                      size: 14.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      state.isNewestFirst
                                          ? 'Newest'
                                          : 'Oldest',
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Content Body
                      if (state is PodcastDetailsLoading ||
                          state is PodcastDetailsInitial) ...[
                        _buildLoadingView(),
                      ] else if (state is PodcastDetailsError) ...[
                        _buildErrorView(state.message),
                      ] else if (state is PodcastDetailsSuccess) ...[
                        if (state.filteredEpisodes.isEmpty) ...[
                          _buildEmptyView(_searchController.text.isNotEmpty),
                        ] else ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.filteredEpisodes.length,
                            itemBuilder: (context, index) {
                              final episode = state.filteredEpisodes[index];
                              return PodcastEpisodeCard(
                                episode: episode,
                                index: index,
                                onTap: () {
                                  _navigateToPlayer(
                                    episodes: state.filteredEpisodes,
                                    initialIndex: index,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Shimmer.fromColors(
            baseColor: context.cardBg,
            highlightColor: AppColors.primary.withAlpha(35),
            child: Padding(
              padding: EdgeInsets.all(14.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 22.h,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Container(
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        width: 32.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: 200.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 56.sp,
            color: Colors.redAccent.withAlpha(180),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n?.error ?? 'Failed to load episodes',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
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
            onPressed: () => _cubit.loadEpisodes(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n?.retry ?? 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 10.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(bool isSearch) {
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 20.w),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch
                ? Icons.search_off_rounded
                : Icons.mic_external_off_rounded,
            size: 56.sp,
            color: context.textSecondary.withValues(alpha: 0.4),
          ),
          SizedBox(height: 12.h),
          Text(
            isSearch
                ? (l10n?.noResultsFound ?? 'No matching episodes found')
                : (l10n?.noEpisodesFound ?? 'No episodes available'),
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
