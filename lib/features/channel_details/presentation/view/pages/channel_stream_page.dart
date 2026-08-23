import 'dart:async';
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
import 'package:s_webview/s_webview.dart' show SWebView;
import 'package:toastification/toastification.dart';

class ChannelStreamPage extends StatefulWidget {
  final ChannelItemEntity channelItem;

  const ChannelStreamPage({super.key, required this.channelItem});

  @override
  State<ChannelStreamPage> createState() => _ChannelStreamPageState();
}

class _ChannelStreamPageState extends State<ChannelStreamPage> {
  late final ChannelStreamCubit _cubit;
  BetterPlayerController? _betterPlayerController;
  String? _activeStreamUrl;
  bool _hasStreamError = false;
  int _retryCount = 0;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    final api = ChannelDetailsApi();
    final ChannelDetailsDataSource dataSource = ChannelDetailsDataSourceImpl(
      api,
    );
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
    _reconnectTimer?.cancel();
    try {
      _betterPlayerController?.dispose();
    } catch (_) {}
    _cubit.close();
    super.dispose();
  }

  bool _isWebStream(String url, String channelId) {
    final lowerUrl = url.toLowerCase().trim();

    // 1. Direct media stream formats -> ALWAYS Native Player (BetterPlayer)
    if (lowerUrl.contains('.m3u8') ||
        lowerUrl.contains('.mp4') ||
        lowerUrl.contains('.ts') ||
        lowerUrl.contains('.m3u') ||
        lowerUrl.contains('playlist') ||
        lowerUrl.contains('/hls/') ||
        lowerUrl.contains('manifest')) {
      return false;
    }

    // 2. Web pages or embeds -> SWebView
    if (lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be') ||
        lowerUrl.contains('rotana.net') ||
        lowerUrl.contains('/channels#/live/') ||
        lowerUrl.contains('#/live/')) {
      return true;
    }

    return false;
  }

  String _formatStreamUrl(String url) {
    if (url.contains('youtube.com/watch?v=')) {
      final videoId = url.split('v=').last.split('&').first;
      return 'https://www.youtube.com/embed/$videoId?autoplay=1';
    } else if (url.contains('youtu.be/')) {
      final videoId = url.split('youtu.be/').last.split('?').first;
      return 'https://www.youtube.com/embed/$videoId?autoplay=1';
    }
    return url;
  }

  Future<void> _setupPlayer(ChannelStreamEntity stream) async {
    final streamUrl = stream.url;
    if (_activeStreamUrl == streamUrl &&
        _betterPlayerController != null &&
        !_hasStreamError) {
      return;
    }

    _activeStreamUrl = streamUrl;
    _reconnectTimer?.cancel();
    if (mounted) {
      setState(() {
        _hasStreamError = false;
      });
    }

    final playerConfig = BetterPlayerConfiguration(
      fit: BoxFit.cover,
      autoPlay: true,
      handleLifecycle: true,
      allowedScreenSleep: false,
      autoDispose: false,
      // autoDetectFullscreenAspectRatio: true,
      // autoDetectFullscreenDeviceOrientation: true,
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        enableQualities: false,
        enablePlayPause: true,
        enableFullscreen: true,
        enableMute: true,
        enableProgressBar: false,
        liveTextColor: Colors.redAccent,
      ),
    );

    final Map<String, String> headers = {};
    if (stream.userAgent != null && stream.userAgent!.isNotEmpty) {
      headers['User-Agent'] = stream.userAgent!;
    } else {
      headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';
    }

    if (stream.referrer != null && stream.referrer!.isNotEmpty) {
      headers['Referer'] = stream.referrer!;
    } else if (streamUrl.contains('rotana') ||
        widget.channelItem.channel.id.toLowerCase().contains('rotana') ||
        widget.channelItem.channel.id.toLowerCase().contains('lbc')) {
      headers['Referer'] = 'https://rotana.net/';
    }

    final dataSource = BetterPlayerDataSource.network(
      streamUrl,
      liveStream: true,
      videoFormat: streamUrl.toLowerCase().contains('.mp4')
          ? BetterPlayerVideoFormat.other
          : BetterPlayerVideoFormat.hls,
      headers: headers.isNotEmpty ? headers : null,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 15000,
        maxBufferMs: 50000,
        bufferForPlaybackMs: 2500,
        bufferForPlaybackAfterRebufferMs: 5000,
      ),
      cacheConfiguration: null,
      useAsmsTracks: true,
      useAsmsSubtitles: false,
      useAsmsAudioTracks: false,
      notificationConfiguration: const BetterPlayerNotificationConfiguration(
        showNotification: false,
      ),
    );

    try {
      if (_betterPlayerController != null) {
        await _betterPlayerController!.setupDataSource(dataSource);
      } else {
        final controller = BetterPlayerController(playerConfig);
        controller.addEventsListener((event) {
          if (event.betterPlayerEventType == BetterPlayerEventType.play ||
              event.betterPlayerEventType == BetterPlayerEventType.progress) {
            _retryCount = 0;
            if (_hasStreamError && mounted) {
              setState(() {
                _hasStreamError = false;
              });
            }
          } else if (event.betterPlayerEventType ==
                  BetterPlayerEventType.exception ||
              event.betterPlayerEventType == BetterPlayerEventType.finished) {
            // Auto-reconnect on transient live stream disconnects
            if (_retryCount < 4) {
              _retryCount++;
              _reconnectTimer?.cancel();
              _reconnectTimer = Timer(const Duration(milliseconds: 1500), () {
                if (mounted && _betterPlayerController != null) {
                  _betterPlayerController!.retryDataSource();
                }
              });
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasStreamError = true;
                  });
                }
              });
            }
          }
        });
        if (mounted) {
          setState(() {
            _betterPlayerController = controller;
          });
        }
        await controller.setupDataSource(dataSource);
      }
    } catch (e) {
      debugPrint('Error setting up BetterPlayer: $e');
      if (_retryCount < 4) {
        _retryCount++;
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _setupPlayer(stream);
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasStreamError = true;
            });
          }
        });
      }
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
                final channelId = widget.channelItem.channel.id;
                if (!_isWebStream(state.selectedStream.url, channelId)) {
                  _setupPlayer(state.selectedStream);
                }
              }
            },
            builder: (context, state) {
              if (state is ChannelStreamLoading ||
                  state is ChannelStreamInitial) {
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
    final channelId = widget.channelItem.channel.id;
    final isWeb = _isWebStream(stream.url, channelId);
    final targetUrl = _formatStreamUrl(stream.url);

    return Column(
      children: [
        // Video Player / WebView Container
        SizedBox(
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: _betterPlayerController!
                .videoPlayerController!
                .value
                .aspectRatio,
            child: ClipRect(
              child: Container(
                height: _betterPlayerController!.videoPlayerController!.value.size!.height,
                color: Colors.black,
                child: isWeb
                    ? SWebView(url: targetUrl, showToolbar: false)
                    : (_hasStreamError
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.wifi_off_rounded,
                                    color: Colors.orangeAccent,
                                    size: 36.sp,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Stream Interrupted',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Tap below to reconnect or switch feed',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _retryCount = 0;
                                      _setupPlayer(stream);
                                    },
                                    icon: Icon(
                                      Icons.refresh_rounded,
                                      size: 16.sp,
                                    ),
                                    label: const Text('Reconnect Stream'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 8.h,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : (_betterPlayerController != null
                                ? BetterPlayer(
                                    controller: _betterPlayerController!,
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryLight,
                                    ),
                                  ))),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(40),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.redAccent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: Colors.redAccent,
                            size: 8.sp,
                          ),
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
                    if (stream.quality != null &&
                        stream.quality!.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
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
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13.sp,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _cubit.selectStream(item);
                            if (!_isWebStream(item.url, channelId)) {
                              _setupPlayer(item);
                            }
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
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
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
