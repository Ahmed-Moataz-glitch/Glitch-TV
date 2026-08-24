import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_radio_player/flutter_radio_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';
import 'package:share_plus/share_plus.dart';

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
  static final FlutterRadioPlayer _player = FlutterRadioPlayer();
  late int _currentIndex;
  late List<RadioStationEntity> _playlist;

  bool _isPlaying = false;
  bool _isLoading = true;
  double _volume = 1.0;
  bool _isMuted = false;
  String _nowPlayingMetadata = '';

  StreamSubscription<bool>? _isPlayingSub;
  StreamSubscription<NowPlayingInfo>? _nowPlayingSub;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

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

  Future<void> _initRadioPlayer() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    _isPlayingSub?.cancel();
    _isPlayingSub = _player.isPlayingStream.listen((isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
          _isLoading = false;
        });
      }
    });

    _nowPlayingSub?.cancel();
    _nowPlayingSub = _player.nowPlayingStream.listen((info) {
      if (mounted) {
        final title = info.title?.trim() ?? '';
        if (title.isNotEmpty) {
          setState(() {
            _nowPlayingMetadata = title;
          });
        }
      }
    });

    try {
      final List<RadioSource> sources = _playlist
          .map(
            (s) => RadioSource(
              url: s.streamUrl.isNotEmpty
                  ? s.streamUrl
                  : 'http://stream.zeno.fm/f3wvbbqmdg8uv',
              title: s.name,
              artwork: s.favicon.isNotEmpty ? s.favicon : null,
            ),
          )
          .toList();

      await _player.initialize(sources, playWhenReady: true);

      if (_currentIndex > 0 && _currentIndex < sources.length) {
        await _player.jumpToSourceAtIndex(_currentIndex);
      }

      await _player.play();
    } catch (e) {
      debugPrint('Radio init warning: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _isPlayingSub?.cancel();
    _nowPlayingSub?.cancel();
    _player.pause();
    super.dispose();
  }

  RadioStationEntity get _currentStation => _playlist[_currentIndex];

  Future<void> _playOrPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _playNext() async {
    if (_currentIndex < _playlist.length - 1) {
      setState(() {
        _currentIndex++;
        _isLoading = true;
        _nowPlayingMetadata = '';
      });
      await _player.jumpToSourceAtIndex(_currentIndex);
      await _player.play();
    }
  }

  Future<void> _playPrevious() async {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isLoading = true;
        _nowPlayingMetadata = '';
      });
      await _player.jumpToSourceAtIndex(_currentIndex);
      await _player.play();
    }
  }

  void _showVolumeDialog() {
    double currentVol = _volume;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              title: Row(
                children: [
                  Icon(
                    currentVol == 0
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 14.sp,
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
      await _player.setVolume(val);
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
    final size = MediaQuery.of(context).size;
    final l10n = context.l10n;

    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
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
                        ? (l10n?.buffering ?? 'CONNECTING...')
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
                      child: ClipOval(
                        child: _currentStation.favicon.isNotEmpty
                            ? Image.network(
                                _currentStation.favicon,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.radio_rounded,
                                  color: AppColors.primaryLight,
                                  size: 80.sp,
                                ),
                              )
                            : Icon(
                                Icons.radio_rounded,
                                color: AppColors.primaryLight,
                                size: 80.sp,
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
    );
  }
}
