import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glitch_tv/core/utils/app_colors.dart';
import 'package:glitch_tv/core/utils/app_theme.dart';
import 'package:glitch_tv/core/utils/app_toast.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/podcast_details/data/services/podcast_download_service.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:share_plus/share_plus.dart';
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
  final PodcastDownloadService _downloadService = PodcastDownloadService();

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

  // Download state for currently active episode
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadedFileSize = '';
  StreamSubscription<double>? _downloadProgressSub;

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

    final foundIndex = _podcastsQueue.indexWhere(
      (element) => element.id == widget.podcast.id,
    );
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
            _isLoading =
                (state.processingState == ProcessingState.loading ||
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

  Future<void> _checkDownloadStatus() async {
    final ep = _currentEpisode;
    if (ep == null) return;
    _downloadProgressSub?.cancel();

    final isDown = await _downloadService.isEpisodeDownloaded(
      podcastId: _currentPodcast.id,
      episodeTitle: ep.title,
      audioUrl: ep.audioUrl,
    );
    final isDownloading = _downloadService.isDownloading(
      _currentPodcast.id,
      ep.audioUrl,
    );
    final progress = _downloadService.getDownloadProgress(
      _currentPodcast.id,
      ep.audioUrl,
    );
    String fileSize = '';
    if (isDown) {
      final size = await _downloadService.getDownloadedFileSize(
        podcastId: _currentPodcast.id,
        episodeTitle: ep.title,
        audioUrl: ep.audioUrl,
      );
      fileSize = _downloadService.formatBytes(size);
    }

    if (mounted) {
      setState(() {
        _isDownloaded = isDown;
        _isDownloading = isDownloading;
        _downloadProgress = progress;
        _downloadedFileSize = fileSize;
      });
    }

    if (isDownloading) {
      _downloadProgressSub = _downloadService
          .getProgressStream(_currentPodcast.id, ep.audioUrl)
          ?.listen((p) {
            if (mounted) {
              setState(() {
                _downloadProgress = p;
                if (p >= 1.0) {
                  _isDownloading = false;
                  _isDownloaded = true;
                  _checkDownloadStatus();
                }
              });
            }
          });
    }
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
        final startIndex =
            (widget.initialEpisodeIndex >= 0 &&
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
              title: context.l10n?.error ?? 'Podcast Stream Error',
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
      final response = await http
          .get(
            Uri.parse(feedUrl),
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'application/rss+xml, application/xml, text/xml, */*',
            },
          )
          .timeout(const Duration(seconds: 15));

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
                final pubDate = pubDateEl.isNotEmpty
                    ? pubDateEl.first.innerText
                    : '';

                episodes.add(
                  PodcastEpisode(title: title, audioUrl: url, pubDate: pubDate),
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

    final ep = _episodesQueue[index];
    final initialDur = _parseDurationString(ep.duration);

    if (mounted) {
      setState(() {
        _currentEpisodeIndex = index;
        _isLoading = true;
        _position = Duration.zero;
        _duration = initialDur;
      });
    }

    try {
      await _audioPlayer.stop();

      // Check download status for UI & offline source selection
      await _checkDownloadStatus();

      // Check if episode is stored locally on device for offline playback
      final downloadedFile = await _downloadService.getDownloadedFile(
        podcastId: _currentPodcast.id,
        episodeTitle: ep.title,
        audioUrl: ep.audioUrl,
      );

      final isOffline = downloadedFile != null && await downloadedFile.exists();

      final artUri = (!isOffline && ep.artworkUrl.isNotEmpty)
          ? Uri.tryParse(ep.artworkUrl)
          : (!isOffline && _currentPodcast.artworkUrl.isNotEmpty
              ? Uri.tryParse(_currentPodcast.artworkUrl)
              : null);

      final mediaItem = MediaItem(
        id: ep.audioUrl,
        album: _currentPodcast.name,
        title: ep.title,
        artist: _currentPodcast.host.isNotEmpty
            ? _currentPodcast.host
            : 'Glitch TV Podcast',
        artUri: artUri,
      );

      AudioSource audioSource;
      if (isOffline) {
        audioSource = AudioSource.file(
          downloadedFile.path,
          tag: mediaItem,
        );
      } else {
        audioSource = AudioSource.uri(
          Uri.parse(ep.audioUrl),
          tag: mediaItem,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': '*/*',
          },
        );
      }

      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing episode index $index: $e');
      if (mounted) {
        AppToast.showToast(
          context: context,
          title: context.l10n?.error ?? 'Playback Error',
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

  Future<void> _handleDownloadAction() async {
    final ep = _currentEpisode;
    if (ep == null) return;
    final l10n = context.l10n;

    if (_isDownloading) {
      AppToast.showToast(
        context: context,
        title: 'Downloading Episode',
        description:
            'Download is currently in progress (${(_downloadProgress * 100).toInt()}%)...',
        type: ToastificationType.info,
      );
      return;
    }

    if (_isDownloaded) {
      // Show bottom sheet to manage / delete download
      showModalBottomSheet(
        context: context,
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.offline_pin_rounded,
                          color: AppColors.primaryLight,
                          size: 32.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Downloaded to Podcasts Folder',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _downloadedFileSize.isNotEmpty
                                  ? 'File Size: $_downloadedFileSize • Saved in Podcasts'
                                  : 'Stored in device Podcasts folder',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    tileColor: Colors.redAccent.withAlpha(20),
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Delete Download',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Remove file from device storage',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _downloadService.deleteDownloadedEpisode(
                        podcastId: _currentPodcast.id,
                        episodeTitle: ep.title,
                        audioUrl: ep.audioUrl,
                      );
                      await _checkDownloadStatus();
                      if (mounted) {
                        AppToast.showToast(
                          context: context,
                          title: 'Download Removed',
                          description:
                              'Episode was deleted from Podcasts folder.',
                          type: ToastificationType.info,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    // Start download
    setState(() {
      _isDownloading = true;
      _isDownloaded = false;
      _downloadProgress = 0.0;
    });

    AppToast.showToast(
      context: context,
      title: 'Download Started',
      description: 'Downloading "${ep.title}" to Podcasts folder...',
      type: ToastificationType.info,
    );

    try {
      await _downloadService.downloadEpisode(
        podcastId: _currentPodcast.id,
        podcastName: _currentPodcast.name,
        podcastHost: _currentPodcast.host,
        podcastArtwork: ep.artworkUrl.isNotEmpty
            ? ep.artworkUrl
            : _currentPodcast.artworkUrl,
        episodeTitle: ep.title,
        audioUrl: ep.audioUrl,
        duration: ep.duration,
        pubDate: ep.pubDate,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _downloadProgress = p;
              if (p >= 1.0) {
                _isDownloading = false;
                _isDownloaded = true;
              }
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
          _downloadProgress = 1.0;
        });
      }

      await _checkDownloadStatus();

      if (mounted) {
        AppToast.showToast(
          context: context,
          title: 'Download Complete',
          description: '"${ep.title}" saved to device Podcasts folder!',
          type: ToastificationType.success,
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = false;
        });
        AppToast.showToast(
          context: context,
          title: l10n?.error ?? 'Download Failed',
          description: 'Could not download episode: $e',
          type: ToastificationType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
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
    _downloadProgressSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    // _audioPlayer.stop();
    // _audioPlayer.dispose();
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
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) {
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
              const Icon(
                Icons.speed_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n?.speed ?? 'Playback Speed',
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
            children: _speeds.map((speed) {
              final isSelected = _playbackSpeed == speed;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                tileColor: isSelected ? AppColors.primary.withAlpha(40) : null,
                title: Text(
                  '${speed}x${speed == 1.0 ? ' (Normal)' : ''}',
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : context.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 15.sp,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      )
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
      await _audioPlayer.setVolume(val);
    } catch (_) {}
  }

  PodcastEpisode? get _currentEpisode =>
      (_currentEpisodeIndex >= 0 &&
          _currentEpisodeIndex < _episodesQueue.length)
      ? _episodesQueue[_currentEpisodeIndex]
      : null;

  Duration _parseDurationString(String s) {
    if (s.isEmpty) return Duration.zero;
    final parts = s.trim().split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final sSec = int.tryParse(parts[2]) ?? 0;
      return Duration(hours: h, minutes: m, seconds: sSec);
    } else if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final sSec = int.tryParse(parts[1]) ?? 0;
      return Duration(minutes: m, seconds: sSec);
    } else if (parts.length == 1) {
      final sec = int.tryParse(parts[0]) ?? 0;
      return Duration(seconds: sec);
    }
    return Duration.zero;
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero && (_currentEpisode?.duration.isNotEmpty ?? false)) {
      final parsed = _parseDurationString(_currentEpisode!.duration);
      if (parsed > Duration.zero) {
        d = parsed;
      }
    }
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Future<void> _sharePodcast() async {
    final ep = _currentEpisode;
    final epTitle = ep?.title ?? _currentPodcast.name;
    final epAudio = ep?.audioUrl ?? _currentPodcast.feedUrl;

    final shareText =
        '🎙️ Listen to "$epTitle" from "${_currentPodcast.name}" on Glitch TV!\n🔗 Stream: $epAudio\nEnjoy top Egyptian podcasts & TV on Glitch TV.';

    try {
      await Share.share(shareText, subject: 'Listen to $epTitle on Glitch TV');
    } catch (e) {
      debugPrint('Error sharing podcast: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final size = MediaQuery.of(context).size;
    final epTitle = _currentEpisode?.title ?? _currentPodcast.name;
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
          l10n?.podcastDetails ?? 'Podcast Player',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Download Action Button
          IconButton(
            tooltip: _isDownloaded
                ? 'Downloaded (Tap to manage)'
                : 'Download Episode',
            icon: (_isDownloading && !_isDownloaded && _downloadProgress < 1.0)
                ? SizedBox(
                    width: 36.r,
                    height: 36.r,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _downloadProgress > 0
                              ? _downloadProgress
                              : null,
                          color: AppColors.primaryLight,
                          strokeWidth: 2.5.r,
                        ),
                        Text(
                          _downloadProgress > 0
                              ? '${(_downloadProgress * 100).toInt()}%'
                              : '',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : Icon(
                    _isDownloaded
                        ? Icons.download_done_rounded
                        : Icons.file_download_outlined,
                    color: _isDownloaded
                        ? AppColors.primaryLight
                        : context.textPrimary,
                    size: 24.sp,
                  ),
            onPressed: _handleDownloadAction,
          ),
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: AppColors.primaryLight,
              size: 22.sp,
            ),
            tooltip: l10n?.share ?? 'Share Podcast',
            onPressed: _sharePodcast,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: Column(
            children: [
              // Podcast Category & Episode Badge & Offline Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(
                        context.isDark ? 30 : 20,
                      ),
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
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: context.isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        'EP ${_currentEpisodeIndex + 1}/${_episodesQueue.length}',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (_isDownloaded) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withAlpha(25),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.primaryLight.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.offline_pin_rounded,
                            size: 16.sp,
                            color: AppColors.primaryLight,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'OFFLINE',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: size.height * 0.04),

              // Podcast Artwork Cover
              Center(
                child: Container(
                  width: 210.w,
                  height: 210.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    color: context.cardBg,
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
                        ? CachedNetworkImage(
                            imageUrl: _currentPodcast.artworkUrl,
                            memCacheWidth: (210 * devicePixelRatio).toInt(),
                            memCacheHeight: (210 * devicePixelRatio).toInt(),
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
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

              SizedBox(height: 32.h),

              // Episode Title & Host
              Text(
                epTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                _currentPodcast.host.isNotEmpty
                    ? 'By ${_currentPodcast.host}'
                    : _currentPodcast.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.textSecondary, fontSize: 13.sp),
              ),

              SizedBox(height: 24.h),

              // Audio Progress Bar & Timestamps
              Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: context.cardBg,
                      thumbColor: AppColors.primaryLight,
                      overlayColor: AppColors.primary.withAlpha(40),
                      trackHeight: 4.h,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      value: _position.inSeconds.toDouble().clamp(
                        0.0,
                        _duration.inSeconds.toDouble() > 0
                            ? _duration.inSeconds.toDouble()
                            : 1.0,
                      ),
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
                          color: context.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          color: context.textSecondary,
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
                        horizontal: 8.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: context.isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        '${_playbackSpeed}x',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Previous Episode
                  IconButton(
                    iconSize: 32.sp,
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: context.textPrimary,
                    ),
                    onPressed: _playPreviousEpisode,
                  ),

                  // Rewind 10s
                  IconButton(
                    iconSize: 32.sp,
                    icon: Icon(
                      Icons.replay_10_rounded,
                      color: context.textPrimary,
                    ),
                    onPressed: () => _seekRelative(-10),
                  ),

                  // Main Play / Pause Button
                  GestureDetector(
                    onTap: _playOrPause,
                    child: Container(
                      width: 65.w,
                      height: 65.h,
                      decoration: const BoxDecoration(
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
                    iconSize: 32.sp,
                    icon: Icon(
                      Icons.forward_10_rounded,
                      color: context.textPrimary,
                    ),
                    onPressed: () => _seekRelative(10),
                  ),

                  // Next Episode
                  IconButton(
                    iconSize: 32.sp,
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: context.textPrimary,
                    ),
                    onPressed: _playNextEpisode,
                  ),

                  // Volume Dialog Button
                  IconButton(
                    iconSize: 32.sp,
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
