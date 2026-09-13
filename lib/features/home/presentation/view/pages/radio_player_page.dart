import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/core/services/app_audio_service.dart';
import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RadioPlayerPage extends StatefulWidget {
  final RadioStationEntity station;
  final List<RadioStationEntity> stationsList;

  const RadioPlayerPage({
    super.key,
    required this.station,
    this.stationsList = const [],
  });

  @override
  State<RadioPlayerPage> createState() => _RadioPlayerPageState();
}

class _RadioPlayerPageState extends State<RadioPlayerPage>
    with SingleTickerProviderStateMixin {
  final AppAudioService _audioService = AppAudioService.instance;
  late int _currentIndex;
  late List<RadioStationEntity> _playlist;

  bool _isPlaying = false;
  bool _isLoading = true;
  double _volume = 1.0;
  bool _isMuted = false;
  String _nowPlayingMetadata = '';
  int _loadGeneration = 0;
  int _retryCount = 0;
  Timer? _reconnectTimer;
  Timer? _connectingWatchdogTimer;
  DateTime? _lastBackPressTime;
  bool _isNetworkConnected = true;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<RadioStationEntity>? _stationChangeSub;
  StreamSubscription<String>? _nowPlayingSub;
  StreamSubscription<double>? _volumeSub;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    try {
      WakelockPlus.enable();
    } catch (_) {}

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _playlist = widget.stationsList.isNotEmpty
        ? widget.stationsList
        : [widget.station];

    final foundIndex = _playlist.indexWhere(
      (element) => element.id == widget.station.id,
    );
    _currentIndex = foundIndex != -1 ? foundIndex : 0;

    _initRadioPlayer();
  }

  void _initRadioPlayer() {
    final currentServiceStation = _audioService.currentStation;
    final isAlreadyPlayingThis = _audioService.currentMode == AudioPlaybackMode.radio &&
        currentServiceStation?.id == _currentStation.id;

    _isPlaying = _audioService.isPlaying && isAlreadyPlayingThis;
    _isLoading = !_isPlaying;
    _volume = _audioService.player.volume;
    _isMuted = _volume == 0.0;
    _nowPlayingMetadata = isAlreadyPlayingThis ? _audioService.nowPlayingIcy : '';

    _playerStateSub = _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.playing) {
            _isLoading = false;
            _retryCount = 0;
            _reconnectTimer?.cancel();
            _connectingWatchdogTimer?.cancel();
          } else if (state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering) {
            _isLoading = true;
          } else {
            _isLoading = false;
          }
        });
      }
    });

    _stationChangeSub = _audioService.stationChangeStream.listen((newStation) {
      if (mounted) {
        final idx = _playlist.indexWhere((s) => s.id == newStation.id);
        if (idx != -1 && idx != _currentIndex) {
          setState(() {
            _currentIndex = idx;
            _nowPlayingMetadata = '';
          });
        }
      }
    });

    _nowPlayingSub = _audioService.nowPlayingIcyStream.listen((title) {
      if (mounted) {
        setState(() {
          _nowPlayingMetadata = title;
        });
      }
    });

    _volumeSub = _audioService.volumeStream.listen((vol) {
      if (mounted) {
        setState(() {
          _volume = vol;
          _isMuted = vol == 0.0;
        });
      }
    });

    if (!isAlreadyPlayingThis || !_audioService.isPlaying) {
      _loadAndPlay();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadAndPlay({bool isRetry = false}) async {
    final int currentGen = ++_loadGeneration;

    if (!isRetry) {
      _retryCount = 0;
      _reconnectTimer?.cancel();
    }
    _connectingWatchdogTimer?.cancel();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _nowPlayingMetadata = '';
      });
    }

    // 25-second watchdog in case stream connection hangs on weak internet
    _connectingWatchdogTimer = Timer(const Duration(seconds: 25), () {
      if (_loadGeneration != currentGen || !mounted) return;
      if (!_isPlaying && _isLoading) {
        debugPrint('Radio connecting watchdog triggered. Retrying...');
        if (_retryCount < 3) {
          _retryCount++;
          _loadAndPlay(isRetry: true);
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    });

    try {
      if (_loadGeneration != currentGen) return;

      await _audioService.playRadioStation(
        station: _currentStation,
        playlist: _playlist,
      );

      if (_loadGeneration != currentGen) return;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_loadGeneration != currentGen) return;

      final errStr = e.toString().toLowerCase();
      if (errStr.contains('abort') ||
          errStr.contains('cancel') ||
          errStr.contains('interrupted') ||
          errStr.contains('connection reset')) {
        return;
      }

      debugPrint('Radio playback error: $e');
      if (_retryCount < 3) {
        _retryCount++;
        final delayMs = _retryCount * 2000;
        debugPrint('Retrying radio playback (attempt $_retryCount of 3) in ${delayMs}ms...');
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
          if (mounted && _loadGeneration == currentGen) {
            _loadAndPlay(isRetry: true);
          }
        });
      } else {
        if (mounted) {
          final l10n = context.l10n;
          AppToast.showToast(
            context: context,
            title: l10n?.error ?? 'Playback Error',
            description: l10n?.streamUnavailable ??
                'Failed to play radio stream. Tap play to retry.',
            type: ToastificationType.error,
          );
        }
      }
    } finally {
      if (mounted && _loadGeneration == currentGen && _retryCount >= 3) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    _reconnectTimer?.cancel();
    _connectingWatchdogTimer?.cancel();
    _pulseController.dispose();
    _playerStateSub?.cancel();
    _stationChangeSub?.cancel();
    _nowPlayingSub?.cancel();
    _volumeSub?.cancel();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  RadioStationEntity get _currentStation => _playlist[_currentIndex];

  Future<void> _playOrPause() async {
    _reconnectTimer?.cancel();
    _connectingWatchdogTimer?.cancel();
    _retryCount = 0;
    try {
      await _audioService.playOrPause();
    } catch (e) {
      debugPrint('Play/Pause error: $e');
      await _loadAndPlay();
    }
  }

  Future<void> _changeStation(int newIndex) async {
    if (_playlist.isEmpty) return;
    _reconnectTimer?.cancel();
    _connectingWatchdogTimer?.cancel();
    _retryCount = 0;

    setState(() {
      _currentIndex = newIndex;
      _isLoading = true;
      _nowPlayingMetadata = '';
    });

    try {
      await _audioService.playRadioStationAtIndex(newIndex);
    } catch (e) {
      debugPrint('Error changing station: $e');
    }
  }

  Future<void> _playNext() async {
    if (_playlist.isEmpty) return;
    final nextIdx = (_currentIndex < _playlist.length - 1) ? _currentIndex + 1 : 0;
    await _changeStation(nextIdx);
  }

  Future<void> _playPrevious() async {
    if (_playlist.isEmpty) return;
    final prevIdx = (_currentIndex > 0) ? _currentIndex - 1 : _playlist.length - 1;
    await _changeStation(prevIdx);
  }

  void _showVolumeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentVol = _isMuted ? 0.0 : _volume;
            return AlertDialog(
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              title: Row(
                children: [
                  Icon(
                    currentVol == 0.0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: AppColors.primaryLight,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Volume Level',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(currentVol * 100).round()}%',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: context.scaffoldBg,
                      thumbColor: AppColors.primaryLight,
                      overlayColor: AppColors.primary.withAlpha(30),
                      trackHeight: 5.h,
                    ),
                    child: Slider(
                      value: currentVol,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) {
                        setDialogState(() {
                          _changeVolume(val);
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    alignment: WrapAlignment.center,
                    children: [0.0, 0.25, 0.5, 0.75, 1.0].map((level) {
                      final label = level == 0.0
                          ? 'Mute'
                          : '${(level * 100).toInt()}%';
                      final isSel = (currentVol - level).abs() < 0.05;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: context.scaffoldBg,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : context.textPrimary,
                          fontSize: 12.sp,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        ),
                        onSelected: (_) {
                          setDialogState(() {
                            _changeVolume(level);
                          });
                        },
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeVolume(double val) async {
    setState(() {
      _volume = val;
      _isMuted = val == 0.0;
    });
    try {
      await _audioService.setVolume(val);
    } catch (_) {}
  }

  Future<void> _shareStation() async {
    final station = _currentStation;
    final tagsText =
        station.tags.isNotEmpty ? '🎵 Genre: ${station.tags}\n' : '';
    final countryText =
        station.country.isNotEmpty ? '🌍 Country: ${station.country}\n' : '';
    final streamUrl =
        station.streamUrl.isNotEmpty ? '🔗 Stream: ${station.streamUrl}\n' : '';

    final shareText =
        '📻 Listen to "${station.name}" live on Glitch TV!\n$tagsText$countryText$streamUrl\nDiscover live radio stations & TV on Glitch TV.';

    try {
      await Share.share(
        shareText,
        subject: 'Listen to ${station.name} on Glitch TV',
      );
    } catch (e) {
      debugPrint('Error sharing radio station: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final size = MediaQuery.of(context).size;
    final l10n = context.l10n;

    return OfflineBuilder(
      debounceDuration: const Duration(seconds: 1),
      connectivityBuilder: (
        BuildContext context,
        List<ConnectivityResult> connectivity,
        Widget childWidget,
      ) {
        final bool isConnected = connectivity.isNotEmpty &&
            !connectivity.contains(ConnectivityResult.none);

        // Auto-reconnect when connection is restored
        if (isConnected && !_isNetworkConnected) {
          _isNetworkConnected = true;
          if (!_isPlaying) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _loadAndPlay(isRetry: true);
              }
            });
          }
        } else if (!isConnected && _isNetworkConnected) {
          _isNetworkConnected = false;
        }

        return childWidget;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          // Double back-press guard to prevent accidental exit from radio
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            AppToast.showToast(
              context: context,
              title: l10n?.pressAgainToExitRadio ?? 'Press back again to exit radio',
              description: l10n?.pressAgainToExitRadioDesc ??
                  'Press back again within 2 seconds to exit',
              type: ToastificationType.info,
            );
            return;
          }

          if (context.mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.homePath);
            }
          }
        },
        child: Scaffold(
          backgroundColor: context.scaffoldBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: context.textPrimary,
                size: 20.sp,
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRouter.homePath);
                }
              },
            ),
            title: Text(
              l10n?.radioPlayer ?? 'Radio Player',
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
                  Icons.share_rounded,
                  color: AppColors.primaryLight,
                  size: 22.sp,
                ),
                tooltip: l10n?.share ?? 'Share Station',
                onPressed: _shareStation,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Non-destructive offline banner indicator
                if (!_isNetworkConnected)
                  Container(
                    width: double.infinity,
                    color: Colors.amber.shade900.withAlpha(220),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            l10n?.noInternetStreamReconnecting ??
                                'No internet connection, reconnecting...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16.h),

                // Live Badge & Status Indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? Colors.redAccent.withAlpha(30)
                        : context.cardBg,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: _isPlaying
                          ? Colors.redAccent
                          : (context.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10.r,
                        height: 10.r,
                        decoration: BoxDecoration(
                          color: _isPlaying
                              ? Colors.redAccent
                              : context.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _isLoading
                            ? (_retryCount > 0
                                ? '${l10n?.weakNetworkReconnecting ?? 'RECONNECTING...'} ($_retryCount/3)'
                                : (l10n?.buffering ?? 'CONNECTING...'))
                            : (_isPlaying
                                ? (l10n?.playingLive ?? 'LIVE STREAM')
                                : (l10n?.paused ?? 'PAUSED')),
                        style: TextStyle(
                          color: _isPlaying
                              ? Colors.redAccent
                              : context.textPrimary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.05),

                // Station Art / Favicon with Animated Glow
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = _isPlaying
                          ? 1.0 + (_pulseController.value * 0.05)
                          : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 200.w,
                          height: 200.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.cardBg,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(
                                  _isPlaying ? 80 : 30,
                                ),
                                blurRadius: 8,
                                spreadRadius: _isPlaying ? 4 : 2,
                              ),
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.all(16.r),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100.r),
                              child: _currentStation.favicon.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: _currentStation.favicon,
                                      memCacheWidth: (200 * devicePixelRatio).toInt(),
                                      memCacheHeight: (200 * devicePixelRatio).toInt(),
                                      fit: BoxFit.fill,
                                      placeholder: (_, __) =>
                                          _buildFallbackStationIcon(),
                                      errorWidget: (_, __, ___) =>
                                          _buildFallbackStationIcon(),
                                    )
                                  : _buildFallbackStationIcon(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 30.h),

                // Station Title & Tags
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      Text(
                        _currentStation.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _nowPlayingMetadata.isNotEmpty
                            ? _nowPlayingMetadata
                            : (_currentStation.tags.isNotEmpty
                                ? _currentStation.tags
                                : 'Egyptian Live Radio Stream'),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.05),
                IconButton(
                  iconSize: 36.sp,
                  icon: Icon(
                    _isMuted || _volume == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: AppColors.primaryLight,
                  ),
                  onPressed: _showVolumeDialog,
                ),
                const Spacer(),

                // Playback Controls Row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        iconSize: 36.sp,
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: _playlist.length > 1
                              ? context.textPrimary
                              : context.textSecondary.withValues(alpha: 0.3),
                        ),
                        onPressed: _playlist.length > 1 ? _playPrevious : null,
                      ),
                      GestureDetector(
                        onTap: _playOrPause,
                        child: Container(
                          width: 72.r,
                          height: 72.r,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: _isLoading
                              ? Center(
                                  child: SizedBox(
                                    width: 28.r,
                                    height: 28.r,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 44.sp,
                                ),
                        ),
                      ),
                      IconButton(
                        iconSize: 36.sp,
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: _playlist.length > 1
                              ? context.textPrimary
                              : context.textSecondary.withValues(alpha: 0.3),
                        ),
                        onPressed: _playlist.length > 1 ? _playNext : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 64.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackStationIcon() {
    final name = _currentStation.name.toLowerCase();
    final tags = _currentStation.tags.toLowerCase();
    final combined = '$name $tags';

    final IconData iconData;
    if (combined.contains('قرآن') ||
        combined.contains('قران') ||
        combined.contains('quran') ||
        combined.contains('islam') ||
        combined.contains('إسلام')) {
      iconData = Icons.auto_stories_rounded;
    } else if (combined.contains('music') ||
        combined.contains('موسيقى') ||
        combined.contains('أغاني') ||
        combined.contains('اغاني') ||
        combined.contains('tarab') ||
        combined.contains('طرب')) {
      iconData = Icons.music_note_rounded;
    } else if (combined.contains('news') ||
        combined.contains('أخبار') ||
        combined.contains('اخبار')) {
      iconData = Icons.newspaper_rounded;
    } else {
      iconData = Icons.radio_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withAlpha(40),
            AppColors.primary.withAlpha(15),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: AppColors.primaryLight,
          size: 72.sp,
        ),
      ),
    );
  }
}
