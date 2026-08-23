import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:toastification/toastification.dart';
import 'package:xml/xml.dart' as xml;

import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';

class PodcastEpisode {
  final String title;
  final String audioUrl;
  final String duration;
  final String pubDate;
  final String artworkUrl;

  const PodcastEpisode({
    required this.title,
    required this.audioUrl,
    this.duration = '',
    this.pubDate = '',
    this.artworkUrl = '',
  });

  factory PodcastEpisode.fromEntity(PodcastEpisodeEntity entity) {
    return PodcastEpisode(
      title: entity.title,
      audioUrl: entity.audioUrl,
      duration: entity.duration,
      pubDate: entity.pubDate,
      artworkUrl: entity.artworkUrl,
    );
  }
}

class PodcastPlayerPage extends StatefulWidget {
  final PodcastEntity podcast;
  final List<PodcastEntity> podcastsList;
  final List<PodcastEpisodeEntity> initialEpisodes;
  final int initialEpisodeIndex;

  const PodcastPlayerPage({
    super.key,
    required this.podcast,
    this.podcastsList = const [],
    this.initialEpisodes = const [],
    this.initialEpisodeIndex = 0,
  });

  @override
  State<PodcastPlayerPage> createState() => _PodcastPlayerPageState();
}

class _PodcastPlayerPageState extends State<PodcastPlayerPage>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;

  late List<PodcastEntity> _podcastsQueue;
  late int _currentPodcastIndex;

  List<PodcastEpisode> _episodesQueue = [];
  int _currentEpisodeIndex = 0;

  bool _isLoading = true;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  bool _isMuted = false;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  final List<double> _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _podcastsQueue = widget.podcastsList.isNotEmpty
        ? widget.podcastsList
        : [widget.podcast];

    final foundIndex =
        _podcastsQueue.indexWhere((element) => element.id == widget.podcast.id);
    _currentPodcastIndex = foundIndex != -1 ? foundIndex : 0;

    _initAudioPlayer();
  }

  PodcastEntity get _currentPodcast => _podcastsQueue[_currentPodcastIndex];

  Future<void> _initAudioPlayer() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _playNextEpisode();
          } else {
            _isLoading = (state.processingState == ProcessingState.loading ||
                    state.processingState == ProcessingState.buffering) &&
                !state.playing;
          }
        });
      }
    });

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() {
          _duration = dur;
        });
      }
    });

    await _loadPodcastFeedAndPlay();
  }

  Future<void> _loadPodcastFeedAndPlay() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _episodesQueue.clear();
        _currentEpisodeIndex = 0;
      });
    }

    try {
      if (widget.initialEpisodes.isNotEmpty &&
          _currentPodcast.id == widget.podcast.id) {
        _episodesQueue = widget.initialEpisodes
            .map((e) => PodcastEpisode.fromEntity(e))
            .toList();
        final startIndex = (widget.initialEpisodeIndex >= 0 &&
                widget.initialEpisodeIndex < _episodesQueue.length)
            ? widget.initialEpisodeIndex
            : 0;
        await _playEpisodeAtIndex(startIndex);
        return;
      }

      final feedUrl = _currentPodcast.feedUrl;
      final parsedEpisodes = await _fetchEpisodesFromFeed(feedUrl);

      if (parsedEpisodes.isNotEmpty) {
        _episodesQueue = parsedEpisodes;
      } else {
        // Fallback episode if RSS resolution returns no enclosures
        _episodesQueue = [
          PodcastEpisode(
            title: _currentPodcast.name,
            audioUrl:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          ),
        ];
      }

      await _playEpisodeAtIndex(0);
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      if (mounted) {
        try {
          _episodesQueue = [
            PodcastEpisode(
              title: _currentPodcast.name,
              audioUrl:
                  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            ),
          ];
          await _playEpisodeAtIndex(0);
        } catch (_) {
          if (mounted) {
            AppToast.showToast(
              context: context,
              title: 'Podcast Stream Error',
              description: 'Could not load podcast stream.',
              type: ToastificationType.error,
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<PodcastEpisode>> _fetchEpisodesFromFeed(String feedUrl) async {
    if (feedUrl.isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse(feedUrl),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept':
              'application/rss+xml, application/xml, text/xml, */*',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final bodyText = utf8.decode(response.bodyBytes, allowMalformed: true);
        final document = xml.XmlDocument.parse(bodyText);
        final items = document.findAllElements('item');
        final episodes = <PodcastEpisode>[];

        for (var item in items) {
          final titleElement = item.findElements('title');
          final enclosureElement = item.findElements('enclosure');
          if (enclosureElement.isNotEmpty) {
            final url = enclosureElement.first.getAttribute('url');
            final type = enclosureElement.first.getAttribute('type') ?? '';
            if (url != null && url.isNotEmpty) {
              if (type.contains('audio') ||
                  url.contains('.mp3') ||
                  url.contains('.m4a') ||
                  url.contains('.aac') ||
                  type.isEmpty) {
                final title = titleElement.isNotEmpty
                    ? titleElement.first.innerText.trim()
                    : _currentPodcast.name;

                final pubDateEl = item.findElements('pubDate');
                final pubDate =
                    pubDateEl.isNotEmpty ? pubDateEl.first.innerText : '';

                episodes.add(
                  PodcastEpisode(
                    title: title,
                    audioUrl: url,
                    pubDate: pubDate,
                  ),
                );
              }
            }
          }
        }
        return episodes;
      }
    } catch (e) {
      debugPrint('RSS feed parsing error: $e');
    }
    return [];
  }

  Future<void> _playEpisodeAtIndex(int index) async {
    if (index < 0 || index >= _episodesQueue.length) return;

    if (mounted) {
      setState(() {
        _currentEpisodeIndex = index;
        _isLoading = true;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }

    try {
      final ep = _episodesQueue[index];
      await _audioPlayer.stop();

      final audioSource = AudioSource.uri(
        Uri.parse(ep.audioUrl),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
        },
      );
      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing episode index $index: $e');
      if (mounted) {
        AppToast.showToast(
          context: context,
          title: 'Playback Error',
          description: 'Failed to play selected episode.',
          type: ToastificationType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playNextEpisode() async {
    if (_currentEpisodeIndex < _episodesQueue.length - 1) {
      await _playEpisodeAtIndex(_currentEpisodeIndex + 1);
    } else if (_podcastsQueue.length > 1) {
      // If at end of episodes, move to next podcast show in playlist
      final nextPodcastIndex =
          (_currentPodcastIndex + 1) % _podcastsQueue.length;
      setState(() {
        _currentPodcastIndex = nextPodcastIndex;
      });
      await _loadPodcastFeedAndPlay();
    }
  }

  Future<void> _playPreviousEpisode() async {
    if (_currentEpisodeIndex > 0) {
      await _playEpisodeAtIndex(_currentEpisodeIndex - 1);
    } else if (_podcastsQueue.length > 1) {
      // Move to previous podcast show in playlist
      final prevPodcastIndex =
          (_currentPodcastIndex - 1 + _podcastsQueue.length) %
              _podcastsQueue.length;
      setState(() {
        _currentPodcastIndex = prevPodcastIndex;
      });
      await _loadPodcastFeedAndPlay();
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playOrPause() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (_) {}
  }

  Future<void> _seekRelative(int seconds) async {
    final newPos = _position + Duration(seconds: seconds);
    final targetPos = newPos < Duration.zero
        ? Duration.zero
        : (newPos > _duration ? _duration : newPos);
    await _audioPlayer.seek(targetPos);
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    setState(() {
      _playbackSpeed = speed;
    });
    await _audioPlayer.setSpeed(speed);
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(color: AppColors.textSecondary.withAlpha(30)),
          ),
          title: Row(
            children: [
              Icon(Icons.speed_rounded,
                  color: AppColors.primaryLight, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                'Playback Speed',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _speeds.map((speed) {
              final isSelected = _playbackSpeed == speed;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                tileColor:
                    isSelected ? AppColors.primary.withAlpha(40) : null,
                title: Text(
                  '${speed}x${speed == 1.0 ? ' (Normal)' : ''}',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15.sp,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded,
                        color: AppColors.primaryLight, size: 20.sp)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _setPlaybackSpeed(speed);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showVolumeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentVol = _isMuted ? 0.0 : _volume;
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(color: AppColors.textSecondary.withAlpha(30)),
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
                      color: AppColors.textPrimary,
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
                      inactiveTrackColor: AppColors.scaffoldBackground,
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
                      final label =
                          level == 0.0 ? 'Mute' : '${(level * 100).toInt()}%';
                      final isSel = (currentVol - level).abs() < 0.05;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.scaffoldBackground,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontSize: 12.sp,
                          fontWeight:
                              isSel ? FontWeight.bold : FontWeight.w500,
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
    await _audioPlayer.setVolume(val);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  PodcastEpisode? get _currentEpisode => _episodesQueue.isNotEmpty &&
          _currentEpisodeIndex >= 0 &&
          _currentEpisodeIndex < _episodesQueue.length
      ? _episodesQueue[_currentEpisodeIndex]
      : null;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final epTitle = _currentEpisode?.title ?? _currentPodcast.name;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Podcast Player',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded,
                color: AppColors.primaryLight, size: 22.sp),
            onPressed: () {
              AppToast.showToast(
                context: context,
                title: 'Share Podcast',
                description: 'Sharing ${_currentPodcast.name}...',
                type: ToastificationType.info,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: Column(
            children: [
              // Podcast Category & Episode Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.primaryLight.withAlpha(50),
                      ),
                    ),
                    child: Text(
                      _currentPodcast.category.isNotEmpty
                          ? _currentPodcast.category.toUpperCase()
                          : 'EGYPTIAN PODCAST',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (_episodesQueue.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.textSecondary.withAlpha(30),
                        ),
                      ),
                      child: Text(
                        'EP ${_currentEpisodeIndex + 1}/${_episodesQueue.length}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: size.height * 0.03),

              // Podcast Artwork Cover
              Center(
                child: Container(
                  width: 210.w,
                  height: 210.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    color: AppColors.card,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(60),
                        blurRadius: 8,
                        spreadRadius: 3,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: _currentPodcast.artworkUrl.isNotEmpty
                        ? Image.network(
                            _currentPodcast.artworkUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.podcasts_rounded,
                              color: AppColors.primaryLight,
                              size: 80.sp,
                            ),
                          )
                        : Icon(
                            Icons.podcasts_rounded,
                            color: AppColors.primaryLight,
                            size: 80.sp,
                          ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Episode Title & Host
              Text(
                epTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                _currentPodcast.host.isNotEmpty
                    ? 'By ${_currentPodcast.host}'
                    : _currentPodcast.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.sp,
                ),
              ),

              SizedBox(height: 24.h),

              // Audio Progress Bar & Timestamps
              Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.card,
                      thumbColor: AppColors.primaryLight,
                      overlayColor: AppColors.primary.withAlpha(40),
                      trackHeight: 4.h,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      value: _position.inSeconds
                          .toDouble()
                          .clamp(0.0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0),
                      min: 0.0,
                      max: _duration.inSeconds > 0
                          ? _duration.inSeconds.toDouble()
                          : 1.0,
                      onChanged: (val) {
                        _audioPlayer.seek(Duration(seconds: val.toInt()));
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Playback Controls Row: Speed Dialog Button, Skip Prev, Rewind 10, Play/Pause, Forward 10, Skip Next, Volume Dialog Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speed Dialog Button
                  GestureDetector(
                    onTap: _showSpeedDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.textSecondary.withAlpha(30),
                        ),
                      ),
                      child: Text(
                        '${_playbackSpeed}x',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Previous Episode
                  IconButton(
                    iconSize: 28.sp,
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: _playPreviousEpisode,
                  ),

                  // Rewind 10s
                  IconButton(
                    iconSize: 26.sp,
                    icon: Icon(
                      Icons.replay_10_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _seekRelative(-10),
                  ),

                  // Main Play / Pause Button
                  GestureDetector(
                    onTap: _playOrPause,
                    child: Container(
                      width: 68.w,
                      height: 68.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: _isLoading && !_isPlaying
                          ? Center(
                              child: SizedBox(
                                width: 26.r,
                                height: 26.r,
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
                              size: 42.sp,
                            ),
                    ),
                  ),

                  // Forward 10s
                  IconButton(
                    iconSize: 26.sp,
                    icon: Icon(
                      Icons.forward_10_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _seekRelative(10),
                  ),

                  // Next Episode
                  IconButton(
                    iconSize: 28.sp,
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: _playNextEpisode,
                  ),

                  // Volume Dialog Button
                  IconButton(
                    iconSize: 26.sp,
                    icon: Icon(
                      _isMuted || _volume == 0
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: AppColors.primaryLight,
                    ),
                    onPressed: _showVolumeDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
