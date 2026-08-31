import 'dart:async';
import 'package:awesome_video_player/awesome_video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/core/view/widgets/offline_wrapper.dart';
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

class _ChannelStreamPageState extends State<ChannelStreamPage>
    with WidgetsBindingObserver {
  late final ChannelStreamCubit _cubit;
  BetterPlayerController? _betterPlayerController;
  String? _activeStreamUrl;
  bool _hasStreamError = false;
  int _retryCount = 0;
  Timer? _reconnectTimer;
  Timer? _playbackWatchdogTimer;
  Timer? _bufferingWatchdogTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _cubit.loadStreams();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      try {
        _betterPlayerController?.pause();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      try {
        if (!_hasStreamError && _betterPlayerController != null) {
          _betterPlayerController?.play();
        }
      } catch (_) {}
    }
  }

  void _disposeCurrentPlayer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _playbackWatchdogTimer?.cancel();
    _playbackWatchdogTimer = null;
    _bufferingWatchdogTimer?.cancel();
    _bufferingWatchdogTimer = null;

    final controller = _betterPlayerController;
    _betterPlayerController = null;
    _activeStreamUrl = null;

    if (controller != null) {
      try {
        controller.pause();
      } catch (e) {
        debugPrint('Error pausing BetterPlayerController: $e');
      }
      try {
        controller.setVolume(0.0);
      } catch (e) {
        debugPrint('Error muting BetterPlayerController: $e');
      }
      try {
        controller.dispose(forceDispose: true);
      } catch (e) {
        debugPrint('Error disposing BetterPlayerController: $e');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCurrentPlayer();
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
        lowerUrl.contains('.mpd') ||
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
        lowerUrl.contains('#/live/') ||
        lowerUrl.endsWith('.html') ||
        lowerUrl.endsWith('.htm') ||
        lowerUrl.contains('dailymotion.com') ||
        lowerUrl.contains('twitch.tv') ||
        lowerUrl.contains('vimeo.com') ||
        lowerUrl.contains('facebook.com')) {
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

  void _trySwitchToNextFeed({bool showToast = false}) {
    if (_isDisposed) return;
    if (_cubit.state is! ChannelStreamSuccess) return;
    final successState = _cubit.state as ChannelStreamSuccess;
    final allStreams = successState.streams;
    if (allStreams.length <= 1) {
      _disposeCurrentPlayer();
      if (mounted) {
        setState(() {
          _hasStreamError = true;
        });
      }
      return;
    }

    final currentIndex = allStreams.indexWhere(
      (s) => s.url == successState.selectedStream.url,
    );
    final nextIndex = (currentIndex + 1) % allStreams.length;
    if (nextIndex == currentIndex) {
      _disposeCurrentPlayer();
      if (mounted) {
        setState(() {
          _hasStreamError = true;
        });
      }
      return;
    }

    final nextStream = allStreams[nextIndex];

    if (showToast && mounted) {
      final l10n = context.l10n;
      AppToast.showToast(
        context: context,
        title: l10n?.streamInterrupted ?? 'Stream Interrupted',
        description: l10n?.switchingToNextFeed ??
            'Stream interrupted. Trying next available feed...',
        type: ToastificationType.warning,
      );
    }

    _disposeCurrentPlayer();
    _retryCount = 0;
    _cubit.selectStream(nextStream);
  }

  Future<void> _setupPlayer(
    ChannelStreamEntity stream, {
    bool isRetry = false,
  }) async {
    if (_isDisposed) return;
    final streamUrl = stream.url.trim();
    if (streamUrl.isEmpty) return;

    if (!isRetry &&
        _activeStreamUrl == streamUrl &&
        _betterPlayerController != null &&
        !_hasStreamError) {
      return;
    }

    try {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _playbackWatchdogTimer?.cancel();
      _bufferingWatchdogTimer?.cancel();

      _disposeCurrentPlayer();
      _activeStreamUrl = streamUrl;

      if (mounted) {
        setState(() {
          _hasStreamError = false;
        });
      }

      // Start 14-second watchdog to prevent infinite loading spinners on dead/hanging streams
      _playbackWatchdogTimer = Timer(const Duration(seconds: 14), () {
        if (_isDisposed || !mounted) return;
        if (!_hasStreamError) {
          debugPrint('Playback watchdog triggered for stream: $streamUrl');
          final successState = _cubit.state is ChannelStreamSuccess
              ? _cubit.state as ChannelStreamSuccess
              : null;
          final hasMultipleFeeds =
              successState != null && successState.streams.length > 1;

          if (hasMultipleFeeds) {
            _trySwitchToNextFeed(showToast: true);
          } else {
            _disposeCurrentPlayer();
            if (mounted) {
              setState(() {
                _hasStreamError = true;
              });
            }
          }
        }
      });

      final betterPlayerConfiguration = BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        autoPlay: true,
        looping: false,
        allowedScreenSleep: false,
        handleLifecycle: true,
        autoDispose: false,
        expandToFill: false,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: true,
          enableFullscreen: true,
          enablePlayPause: true,
          enableMute: true,
          enableProgressBar: false,
          enableProgressBarDrag: false,
          enableProgressText: false,
          enableSkips: false,
          enableQualities: true,
          enableAudioTracks: true,
          enableSubtitles: true,
          enablePlaybackSpeed: false,
          controlBarColor: Colors.black.withAlpha(180),
          iconsColor: Colors.white,
          loadingColor: AppColors.primaryLight,
          progressBarPlayedColor: AppColors.primary,
          progressBarHandleColor: AppColors.primaryLight,
          overflowModalColor: AppColors.card,
          overflowModalTextColor: AppColors.textPrimary,
          overflowMenuIconsColor: AppColors.primaryLight,
        ),
        errorBuilder: (context, errorMessage) {
          return _buildErrorOverlay(stream);
        },
      );

      // Build streaming-optimized HTTP headers
      final Map<String, String> headers = {
        'User-Agent':
            (stream.userAgent != null && stream.userAgent!.trim().isNotEmpty)
                ? stream.userAgent!.trim()
                : 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };

      if (stream.referrer != null && stream.referrer!.trim().isNotEmpty) {
        headers['Referer'] = stream.referrer!.trim();
      }

      // Determine specific video format to assist ExoPlayer/AVPlayer extractor selection
      BetterPlayerVideoFormat videoFormat = BetterPlayerVideoFormat.other;
      final lowerUrl = streamUrl.toLowerCase();
      if (lowerUrl.contains('.m3u8') ||
          lowerUrl.contains('/hls') ||
          lowerUrl.contains('hls.') ||
          lowerUrl.contains('playlist') ||
          lowerUrl.contains('.m3u') ||
          lowerUrl.contains('chunklist') ||
          lowerUrl.contains('/stream/') ||
          lowerUrl.contains('live') ||
          lowerUrl.contains('.ts')) {
        videoFormat = BetterPlayerVideoFormat.hls;
      } else if (lowerUrl.contains('.mpd') || lowerUrl.contains('/dash')) {
        videoFormat = BetterPlayerVideoFormat.dash;
      } else if (lowerUrl.contains('.ism')) {
        videoFormat = BetterPlayerVideoFormat.ss;
      }

      final betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        streamUrl,
        videoFormat: videoFormat,
        liveStream: true,
        headers: headers,
        useAsmsTracks: true,
        useAsmsAudioTracks: true,
        useAsmsSubtitles: true,
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 20000,
          maxBufferMs: 60000,
          bufferForPlaybackMs: 2000,
          bufferForPlaybackAfterRebufferMs: 3500,
        ),
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: false,
        ),
      );

      final controller = BetterPlayerController(
        betterPlayerConfiguration,
        betterPlayerDataSource: betterPlayerDataSource,
      );

      controller.addEventsListener((event) {
        if (_isDisposed) return;
        final type = event.betterPlayerEventType;

        if (type == BetterPlayerEventType.initialized) {
          _playbackWatchdogTimer?.cancel();
          _playbackWatchdogTimer = null;
          _bufferingWatchdogTimer?.cancel();
          _bufferingWatchdogTimer = null;
          _retryCount = 0;
          try {
            controller.play();
          } catch (_) {}
          if (_hasStreamError && mounted) {
            setState(() {
              _hasStreamError = false;
            });
          }
        } else if (type == BetterPlayerEventType.play) {
          _playbackWatchdogTimer?.cancel();
          _playbackWatchdogTimer = null;
          _bufferingWatchdogTimer?.cancel();
          _bufferingWatchdogTimer = null;
          if (_hasStreamError && mounted) {
            setState(() {
              _hasStreamError = false;
            });
          }
        } else if (type == BetterPlayerEventType.bufferingStart) {
          _bufferingWatchdogTimer?.cancel();
          _bufferingWatchdogTimer = Timer(const Duration(seconds: 12), () {
            if (_isDisposed || !mounted) return;
            debugPrint('Buffering watchdog triggered for stream: $streamUrl');
            final successState = _cubit.state is ChannelStreamSuccess
                ? _cubit.state as ChannelStreamSuccess
                : null;
            final hasMultipleFeeds =
                successState != null && successState.streams.length > 1;
            if (hasMultipleFeeds) {
              _trySwitchToNextFeed(showToast: true);
            } else {
              _disposeCurrentPlayer();
              if (mounted) {
                setState(() {
                  _hasStreamError = true;
                });
              }
            }
          });
        } else if (type == BetterPlayerEventType.bufferingEnd) {
          _bufferingWatchdogTimer?.cancel();
          _bufferingWatchdogTimer = null;
        } else if (type == BetterPlayerEventType.exception) {
          _playbackWatchdogTimer?.cancel();
          _playbackWatchdogTimer = null;
          _bufferingWatchdogTimer?.cancel();
          _bufferingWatchdogTimer = null;
          debugPrint(
            'BetterPlayer error: ${event.parameters?['exception'] ?? 'unknown'}',
          );
          if (_isDisposed || !mounted) return;
          if (!_hasStreamError) {
            final successState = _cubit.state is ChannelStreamSuccess
                ? _cubit.state as ChannelStreamSuccess
                : null;
            final hasMultipleFeeds =
                successState != null && successState.streams.length > 1;

            if (hasMultipleFeeds && _retryCount >= 1) {
              _trySwitchToNextFeed(showToast: true);
            } else if (_retryCount < 1) {
              _retryCount++;
              _reconnectTimer?.cancel();
              _reconnectTimer = Timer(const Duration(milliseconds: 1500), () {
                if (!_isDisposed && mounted) {
                  _setupPlayer(stream, isRetry: true);
                }
              });
            } else {
              _disposeCurrentPlayer();
              if (mounted) {
                setState(() {
                  _hasStreamError = true;
                });
              }
            }
          }
        }
      });

      if (mounted && !_isDisposed) {
        setState(() {
          _betterPlayerController = controller;
        });
      } else {
        try {
          controller.dispose(forceDispose: true);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error initializing BetterPlayerController: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _hasStreamError = true;
        });
      }
    }
  }

  Widget _buildErrorOverlay(ChannelStreamEntity stream) {
    final l10n = context.l10n;
    final successState = _cubit.state is ChannelStreamSuccess
        ? _cubit.state as ChannelStreamSuccess
        : null;
    final hasMultipleFeeds =
        successState != null && successState.streams.length > 1;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.signal_cellular_connected_no_internet_4_bar_rounded,
              color: Colors.redAccent,
              size: 36.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              l10n?.streamInterrupted ?? 'Stream Interrupted',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              l10n?.reconnectPrompt ?? 'Tap below to reconnect or switch feed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _retryCount = 0;
                    _activeStreamUrl = null;
                    _setupPlayer(stream);
                  },
                  icon: Icon(Icons.refresh_rounded, size: 16.sp),
                  label: Text(l10n?.reconnectStream ?? 'Reconnect Stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                if (hasMultipleFeeds)
                  ElevatedButton.icon(
                    onPressed: () => _trySwitchToNextFeed(showToast: false),
                    icon: Icon(Icons.skip_next_rounded, size: 16.sp),
                    label: Text(l10n?.tryNextFeed ?? 'Try Next Feed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final channel = widget.channelItem.channel;
    final logoUrl = widget.channelItem.logoUrl;
    final l10n = context.l10n;

    return OfflineWrapper(
      onRetry: () {
        _disposeCurrentPlayer();
        _retryCount = 0;
        _cubit.loadStreams(forceRefresh: true);
      },
      offlineBuilder: (context) {
        _disposeCurrentPlayer();
        return Scaffold(
          backgroundColor: context.scaffoldBg,
          appBar: AppBar(
            backgroundColor: context.scaffoldBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: context.textPrimary,
                size: 24.sp,
              ),
              onPressed: () {
                _disposeCurrentPlayer();
                context.pop();
              },
            ),
            title: Row(
              children: [
                if (logoUrl.isNotEmpty) ...[
                  SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: CachedNetworkImage(
                      imageUrl: logoUrl,
                      memCacheWidth: (40 * devicePixelRatio).toInt(),
                      memCacheHeight: (40 * devicePixelRatio).toInt(),
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
                      color: context.textPrimary,
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
            child: OfflineFallbackView(
              onRetry: () {
                _disposeCurrentPlayer();
                _retryCount = 0;
                _cubit.loadStreams(forceRefresh: true);
              },
              onGoToDownloads: () {
                context.push(AppRouter.downloadsPath);
              },
            ),
          ),
        );
      },
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          _disposeCurrentPlayer();
        },
        child: BlocProvider.value(
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
                  size: 24.sp,
                ),
                onPressed: () {
                  _disposeCurrentPlayer();
                  context.pop();
                },
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (logoUrl.isNotEmpty) ...[
                    Container(
                      width: 40.w,
                      height: 40.h,
                      margin: EdgeInsets.only(right: 8.w),
                      child: CachedNetworkImage(
                        imageUrl: logoUrl,
                        memCacheWidth: (40 * devicePixelRatio).toInt(),
                        memCacheHeight: (40 * devicePixelRatio).toInt(),
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
                        color: context.textPrimary,
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
                  if (_isDisposed) return;
                  if (state is ChannelStreamError) {
                    AppToast.showToast(
                      context: context,
                      title: l10n?.error ?? 'Stream Error',
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
                  if (_isDisposed) {
                    return const SizedBox.shrink();
                  }

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
        ),
      ),
    );
  }

  Widget _buildPlayerContent(ChannelStreamSuccess state) {
    if (_isDisposed) return const SizedBox.shrink();

    final stream = state.selectedStream;
    final channelId = widget.channelItem.channel.id;
    final isWeb = _isWebStream(stream.url, channelId);
    final targetUrl = _formatStreamUrl(stream.url);
    final l10n = context.l10n;

    // Ensure player is initialized if not yet started
    if (!isWeb &&
        _betterPlayerController == null &&
        !_hasStreamError &&
        _activeStreamUrl != stream.url) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted && _betterPlayerController == null) {
          _setupPlayer(stream);
        }
      });
    }

    return Column(
      children: [
        // Video Player / WebView Container
        AspectRatio(
          aspectRatio: 16 / 9,
          child: isWeb
              ? SWebView(url: targetUrl, showToolbar: false)
              : (_hasStreamError
                    ? _buildErrorOverlay(stream)
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
                            l10n?.live ?? 'LIVE',
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          stream.label!,
                          style: TextStyle(
                            color: context.textSecondary,
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
                    l10n?.availableFeeds(state.streams.length) ??
                        'Available Stream Feeds (${state.streams.length})',
                    style: TextStyle(
                      color: context.textPrimary,
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
                        backgroundColor: context.cardBg,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : context.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13.sp,
                        ),
                        onSelected: (selected) {
                          if (selected && stream.url != item.url) {
                            _retryCount = 0;
                            _disposeCurrentPlayer();
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
    final l10n = context.l10n;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: context.cardBg,
            highlightColor: AppColors.primary.withAlpha(60),
            child: Container(
              width: 320.w,
              height: 180.h,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            l10n?.fetchingStream ?? 'Fetching channel stream...',
            style: TextStyle(color: context.textSecondary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: context.cardBg,
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
                l10n?.streamUnavailable ?? 'Stream Unavailable',
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
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: () => _cubit.loadStreams(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n?.retry ?? 'Retry'),
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
