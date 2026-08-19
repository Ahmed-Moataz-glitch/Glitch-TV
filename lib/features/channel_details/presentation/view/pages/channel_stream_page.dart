import 'package:awesome_video_player/awesome_video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/features/channel_details/data/api/channel_details_api.dart';
import 'package:glitch_tv/features/channel_details/data/repo/data_source/channel_details_data_source_impl.dart';
import 'package:glitch_tv/features/channel_details/data/repo/repo/channel_details_repo_impl.dart';
import 'package:glitch_tv/features/channel_details/domain/entities/channel_stream_entity.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/data_source/channel_details_data_source.dart';
import 'package:glitch_tv/features/channel_details/domain/repo/repo/channel_details_repo.dart';
import 'package:glitch_tv/features/channel_details/domain/use_case/fetch_channel_streams_use_case.dart';
import 'package:glitch_tv/features/channel_details/presentation/view_model/channel_stream_cubit.dart';
import 'package:glitch_tv/features/channel_details/presentation/view_model/channel_stream_state.dart';
import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';

class ChannelStreamPage extends StatefulWidget {
  final ChannelItemEntity channelItem;

  const ChannelStreamPage({
    super.key,
    required this.channelItem,
  });

  @override
  State<ChannelStreamPage> createState() => _ChannelStreamPageState();
}

class _ChannelStreamPageState extends State<ChannelStreamPage> {
  late final ChannelStreamCubit _cubit;
  BetterPlayerController? _betterPlayerController;
  String? _activeStreamUrl;

  @override
  void initState() {
    super.initState();
    final api = ChannelDetailsApi();
    final ChannelDetailsDataSource dataSource = ChannelDetailsDataSourceImpl(api);
    final ChannelDetailsRepo repo = ChannelDetailsRepoImpl(dataSource);
    final useCase = FetchChannelStreamsUseCase(repo);

    _cubit = ChannelStreamCubit(
      fetchChannelStreamsUseCase: useCase,
      channelItem: widget.channelItem,
    );

    _cubit.loadStreams();
  }

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    _cubit.close();
    super.dispose();
  }

  void _setupPlayer(ChannelStreamEntity stream) {
    if (_activeStreamUrl == stream.url && _betterPlayerController != null) {
      return;
    }

    _activeStreamUrl = stream.url;

    const playerConfig = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.fill,
      expandToFill: true,
      autoPlay: true,
      handleLifecycle: true,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        enableQualities: true,
        enablePlayPause: true,
        enableFullscreen: true,
      ),
    );

    final Map<String, String> headers = {};
    if (stream.userAgent != null && stream.userAgent!.isNotEmpty) {
      headers['User-Agent'] = stream.userAgent!;
    }
    if (stream.referrer != null && stream.referrer!.isNotEmpty) {
      headers['Referer'] = stream.referrer!;
    }

    final dataSource = BetterPlayerDataSource.network(
      stream.url,
      liveStream: true,
      videoFormat: BetterPlayerVideoFormat.hls,
      headers: headers.isNotEmpty ? headers : null,
      // Caching is disabled for live HLS streams so ExoPlayer fetches dynamic live chunks directly from network
      cacheConfiguration: null,
    );

    if (_betterPlayerController != null) {
      _betterPlayerController!.setupDataSource(dataSource);
    } else {
      final controller = BetterPlayerController(playerConfig);
      controller.addEventsListener((event) {
        if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
          if (mounted) {
            AppToast.showToast(
              context: context,
              title: 'Stream Error',
              description: 'Stream connection lost or failed to load.',
              type: ToastificationType.error,
            );
          }
        }
      });
      setState(() {
        _betterPlayerController = controller;
      });
      controller.setupDataSource(dataSource);
    }
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channelItem.channel;
    final logoUrl = widget.channelItem.logoUrl;

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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logoUrl.isNotEmpty) ...[
                Container(
                  width: 28.w,
                  height: 28.h,
                  margin: EdgeInsets.only(right: 8.w),
                  child: CachedNetworkImage(
                    imageUrl: logoUrl,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.live_tv,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
              Flexible(
                child: Text(
                  channel.name.isNotEmpty ? channel.name : channel.id,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: BlocConsumer<ChannelStreamCubit, ChannelStreamState>(
            listener: (context, state) {
              if (state is ChannelStreamError) {
                AppToast.showToast(
                  context: context,
                  title: 'Stream Error',
                  description: state.message,
                  type: ToastificationType.error,
                );
              } else if (state is ChannelStreamSuccess) {
                _setupPlayer(state.selectedStream);
              }
            },
            builder: (context, state) {
              if (state is ChannelStreamLoading || state is ChannelStreamInitial) {
                return _buildLoadingView();
              }

              if (state is ChannelStreamError) {
                return _buildErrorView(state.message);
              }

              if (state is ChannelStreamSuccess) {
                return _buildPlayerContent(state);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerContent(ChannelStreamSuccess state) {
    final stream = state.selectedStream;
    return Column(
      children: [
        // Video Player Container
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: _betterPlayerController != null
                ? BetterPlayer(controller: _betterPlayerController!)
                : Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryLight,
                    ),
                  ),
          ),
        ),

        // Stream Info & Feeds Selector
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(40),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.redAccent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.redAccent, size: 8.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stream.quality != null && stream.quality!.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(150),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          stream.quality!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (stream.label != null && stream.label!.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          stream.label!,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 16.h),

                // Available Stream Sources / Feeds
                if (state.streams.length > 1) ...[
                  Text(
                    'Available Stream Feeds (${state.streams.length})',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: List.generate(state.streams.length, (index) {
                      final item = state.streams[index];
                      final isSelected = item.url == stream.url;
                      final label = item.title.isNotEmpty
                          ? item.title
                          : (item.quality != null && item.quality!.isNotEmpty
                              ? 'Feed ${index + 1} (${item.quality})'
                              : 'Feed ${index + 1}');

                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.card,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13.sp,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _cubit.selectStream(item);
                          }
                        },
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: AppColors.card,
            highlightColor: AppColors.primary.withAlpha(60),
            child: Container(
              width: 320.w,
              height: 180.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Fetching channel stream...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tv_off_rounded,
                size: 54.sp,
                color: Colors.redAccent.withAlpha(200),
              ),
              SizedBox(height: 16.h),
              Text(
                'Stream Unavailable',
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
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: () => _cubit.loadStreams(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
