import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/features/channel_details/data/api/channel_details_api.dart';
import 'package:glitch_tv/features/channel_details/data/repo/data_source/channel_details_data_source_impl.dart';
import 'package:glitch_tv/features/channel_details/data/repo/repo/channel_details_repo_impl.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/data_source/channel_details_data_source.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/repo/channel_details_repo.dart';
import 'package:glitch_tv/features/channel_details/domain/use_case/fetch_epg_guide_use_case.dart';
import 'package:glitch_tv/features/channel_details/presentation/view/widgets/channel_info_header.dart';
import 'package:glitch_tv/features/channel_details/presentation/view/widgets/epg_card.dart';
import 'package:glitch_tv/features/channel_details/presentation/view_model/channel_details_cubit.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';

class ChannelDetailsPage extends StatefulWidget {
  final ChannelItemEntity channelItem;

  const ChannelDetailsPage({
    super.key,
    required this.channelItem,
  });

  @override
  State<ChannelDetailsPage> createState() => _ChannelDetailsPageState();
}

class _ChannelDetailsPageState extends State<ChannelDetailsPage> {
  late final ChannelDetailsCubit _cubit;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final api = ChannelDetailsApi();
    final ChannelDetailsDataSource dataSource =
        ChannelDetailsDataSourceImpl(api);
    final ChannelDetailsRepo repo = ChannelDetailsRepoImpl(dataSource);
    final useCase = FetchEpgGuideUseCase(repo);

    _cubit = ChannelDetailsCubit(
      fetchEpgGuideUseCase: useCase,
      channelItem: widget.channelItem,
    );

    _cubit.loadEpg();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channelItem.channel;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.scaffoldBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20.sp,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            channel.name.isNotEmpty ? channel.name : channel.id,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite
                    ? AppColors.primaryLight
                    : AppColors.textSecondary,
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
              await _cubit.loadEpg(forceRefresh: true);
            },
            color: AppColors.primaryLight,
            backgroundColor: AppColors.card,
            child: BlocConsumer<ChannelDetailsCubit, ChannelDetailsState>(
              listener: (context, state) {
                if (state is ChannelDetailsError) {
                  AppToast.showToast(
                    context: context,
                    title: 'Error',
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
                      // Header Widget
                      ChannelInfoHeader(item: widget.channelItem),
                      SizedBox(height: 24.h),

                      // EPG Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.primaryLight,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "Today's EPG Guide",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (state is ChannelDetailsSuccess)
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
                                '${state.todayProgrammes.length} shows',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Content states
                      if (state is ChannelDetailsLoading ||
                          state is ChannelDetailsInitial) ...[
                        _buildLoadingView(),
                      ] else if (state is ChannelDetailsError) ...[
                        _buildErrorView(state.message),
                      ] else if (state is ChannelDetailsSuccess) ...[
                        if (state.todayProgrammes.isEmpty) ...[
                          _buildEmptyView(),
                        ] else ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.todayProgrammes.length,
                            itemBuilder: (context, index) {
                              final prog = state.todayProgrammes[index];
                              return EpgCard(programme: prog);
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
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Shimmer.fromColors(
            baseColor: AppColors.card,
            highlightColor: AppColors.primary.withAlpha(40),
            child: Container(
              width: double.infinity,
              height: 90.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Container(
      padding: EdgeInsets.all(24.r),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 48.sp,
            color: Colors.redAccent.withAlpha(180),
          ),
          SizedBox(height: 12.h),
          Text(
            'Failed to load EPG guide',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: () => _cubit.loadEpg(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
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

  Widget _buildEmptyView() {
    return Container(
      padding: EdgeInsets.all(32.r),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 48.sp,
            color: AppColors.textSecondary.withAlpha(120),
          ),
          SizedBox(height: 12.h),
          Text(
            'No guide available for today',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'No EPG schedule data was found for this channel today.',
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
