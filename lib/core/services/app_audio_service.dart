import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';
import 'package:glitch_tv/features/podcast_details/domain/entities/podcast_episode_entity.dart';
import 'package:glitch_tv/features/podcast_details/data/services/podcast_download_service.dart';

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

enum AudioPlaybackMode {
  none,
  radio,
  podcast,
}

class AppAudioService {
  static final AppAudioService instance = AppAudioService._internal();
  factory AppAudioService() => instance;

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  AudioPlaybackMode _currentMode = AudioPlaybackMode.none;
  AudioPlaybackMode get currentMode => _currentMode;

  // Radio state
  List<RadioStationEntity> _radioPlaylist = [];
  List<RadioStationEntity> get radioPlaylist => List.unmodifiable(_radioPlaylist);

  int _currentRadioIndex = 0;
  int get currentRadioIndex => _currentRadioIndex;

  RadioStationEntity? get currentStation {
    if (_radioPlaylist.isNotEmpty &&
        _currentRadioIndex >= 0 &&
        _currentRadioIndex < _radioPlaylist.length) {
      return _radioPlaylist[_currentRadioIndex];
    }
    return null;
  }

  String _nowPlayingIcy = '';
  String get nowPlayingIcy => _nowPlayingIcy;

  // Podcast state
  PodcastEntity? _currentPodcast;
  PodcastEntity? get currentPodcast => _currentPodcast;

  List<PodcastEpisode> _podcastQueue = [];
  List<PodcastEpisode> get podcastQueue => List.unmodifiable(_podcastQueue);

  int _currentPodcastIndex = 0;
  int get currentPodcastIndex => _currentPodcastIndex;

  PodcastEpisode? get currentEpisode {
    if (_podcastQueue.isNotEmpty &&
        _currentPodcastIndex >= 0 &&
        _currentPodcastIndex < _podcastQueue.length) {
      return _podcastQueue[_currentPodcastIndex];
    }
    return null;
  }

  double _playbackSpeed = 1.0;
  double get playbackSpeed => _playbackSpeed;

  // Broadcast stream controllers
  final StreamController<AudioPlaybackMode> _modeController =
      StreamController<AudioPlaybackMode>.broadcast();
  Stream<AudioPlaybackMode> get modeStream => _modeController.stream;

  final StreamController<RadioStationEntity> _stationChangeController =
      StreamController<RadioStationEntity>.broadcast();
  Stream<RadioStationEntity> get stationChangeStream =>
      _stationChangeController.stream;

  final StreamController<PodcastEpisode> _episodeChangeController =
      StreamController<PodcastEpisode>.broadcast();
  Stream<PodcastEpisode> get episodeChangeStream =>
      _episodeChangeController.stream;

  final StreamController<String> _nowPlayingIcyController =
      StreamController<String>.broadcast();
  Stream<String> get nowPlayingIcyStream => _nowPlayingIcyController.stream;

  // Convenience stream getters from AudioPlayer
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<double> get speedStream => _player.speedStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  bool get isPlaying => _player.playing;
  Duration get currentPosition => _player.position;
  Duration? get totalDuration => _player.duration;

  AppAudioService._internal() {
    _init();
  }

  void _init() {
    // Synchronize lockscreen / remote button clicks with Flutter UI
    _player.currentIndexStream.listen((index) {
      if (index == null) return;
      if (_currentMode == AudioPlaybackMode.radio) {
        if (index >= 0 &&
            index < _radioPlaylist.length &&
            index != _currentRadioIndex) {
          _currentRadioIndex = index;
          _nowPlayingIcy = '';
          _nowPlayingIcyController.add('');
          _stationChangeController.add(_radioPlaylist[index]);
        }
      } else if (_currentMode == AudioPlaybackMode.podcast) {
        if (index >= 0 &&
            index < _podcastQueue.length &&
            index != _currentPodcastIndex) {
          _currentPodcastIndex = index;
          _episodeChangeController.add(_podcastQueue[index]);
        }
      }
    });

    // Listen to ICY radio stream metadata (song / show title)
    _player.icyMetadataStream.listen((icy) {
      if (_currentMode == AudioPlaybackMode.radio) {
        final title = icy?.info?.title?.trim() ?? '';
        if (title.isNotEmpty && title != _nowPlayingIcy) {
          _nowPlayingIcy = title;
          _nowPlayingIcyController.add(title);
        }
      }
    });

    // Auto-advance podcast episode when completed
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_currentMode == AudioPlaybackMode.podcast) {
          skipToNextPodcastEpisode();
        }
      }
    });
  }

  // ==========================================
  // RADIO PLAYBACK
  // ==========================================

  Future<void> playRadioStation({
    required RadioStationEntity station,
    List<RadioStationEntity> playlist = const [],
  }) async {
    final stations = playlist.isNotEmpty ? playlist : [station];
    final foundIndex = stations.indexWhere((s) => s.id == station.id);
    final targetIndex = foundIndex != -1 ? foundIndex : 0;

    // If already playing this exact radio station, do not re-initialize
    if (_currentMode == AudioPlaybackMode.radio &&
        currentStation?.id == station.id &&
        _player.playing) {
      return;
    }

    _currentMode = AudioPlaybackMode.radio;
    _modeController.add(_currentMode);
    _radioPlaylist = stations;
    _currentRadioIndex = targetIndex;
    _nowPlayingIcy = '';
    _nowPlayingIcyController.add('');
    _stationChangeController.add(stations[_currentRadioIndex]);

    final audioSources = stations.map((s) {
      final streamUrl = s.streamUrl.isNotEmpty
          ? s.streamUrl.trim()
          : 'http://stream.zeno.fm/f3wvbbqmdg8uv';
      final artUri = s.favicon.isNotEmpty ? Uri.tryParse(s.favicon.trim()) : null;

      return AudioSource.uri(
        Uri.parse(streamUrl),
        tag: MediaItem(
          id: s.id.isNotEmpty ? s.id : streamUrl,
          album: s.tags.isNotEmpty ? s.tags : 'Live Radio',
          title: s.name,
          artist: 'Glitch TV Radio',
          artUri: artUri,
        ),
      );
    }).toList();

    try {
      await _player.stop();
      await _player.setAudioSources(
        audioSources,
        initialIndex: _currentRadioIndex,
        initialPosition: Duration.zero,
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error playing radio station: $e');
      rethrow;
    }
  }

  Future<void> playRadioStationAtIndex(int index) async {
    if (index < 0 || index >= _radioPlaylist.length) return;
    _currentRadioIndex = index;
    _nowPlayingIcy = '';
    _nowPlayingIcyController.add('');
    _stationChangeController.add(_radioPlaylist[index]);

    try {
      await _player.seek(Duration.zero, index: index);
      if (!_player.playing) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('Error switching radio station index: $e');
    }
  }

  Future<void> skipToNextRadioStation() async {
    if (_radioPlaylist.isEmpty) return;
    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
      await playRadioStationAtIndex(0);
    }
  }

  Future<void> skipToPreviousRadioStation() async {
    if (_radioPlaylist.isEmpty) return;
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await playRadioStationAtIndex(_radioPlaylist.length - 1);
    }
  }

  // ==========================================
  // PODCAST PLAYBACK
  // ==========================================

  Future<void> playPodcast({
    required PodcastEntity podcast,
    required List<PodcastEpisode> episodes,
    required int initialIndex,
    required PodcastDownloadService downloadService,
  }) async {
    if (episodes.isEmpty) return;

    final targetIndex =
        (initialIndex >= 0 && initialIndex < episodes.length) ? initialIndex : 0;

    // Check if the exact episode is already playing
    if (_currentMode == AudioPlaybackMode.podcast &&
        _currentPodcast?.id == podcast.id &&
        _currentPodcastIndex == targetIndex &&
        _player.playing) {
      return;
    }

    _currentMode = AudioPlaybackMode.podcast;
    _modeController.add(_currentMode);
    _currentPodcast = podcast;
    _podcastQueue = episodes;
    _currentPodcastIndex = targetIndex;
    _episodeChangeController.add(episodes[_currentPodcastIndex]);

    final List<AudioSource> sources = [];
    for (final ep in episodes) {
      final downloadedFile = await downloadService.getDownloadedFile(
        podcastId: podcast.id,
        episodeTitle: ep.title,
        audioUrl: ep.audioUrl,
      );
      final isOffline = downloadedFile != null && await downloadedFile.exists();

      final artUri = (!isOffline && ep.artworkUrl.isNotEmpty)
          ? Uri.tryParse(ep.artworkUrl)
          : (!isOffline && podcast.artworkUrl.isNotEmpty
              ? Uri.tryParse(podcast.artworkUrl)
              : null);

      final mediaItem = MediaItem(
        id: ep.audioUrl,
        album: podcast.name,
        title: ep.title,
        artist: podcast.host.isNotEmpty ? podcast.host : 'Glitch TV Podcast',
        artUri: artUri,
      );

      if (isOffline) {
        sources.add(
          AudioSource.file(
            downloadedFile.path,
            tag: mediaItem,
          ),
        );
      } else {
        sources.add(
          AudioSource.uri(
            Uri.parse(ep.audioUrl),
            tag: mediaItem,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': '*/*',
            },
          ),
        );
      }
    }

    try {
      await _player.stop();
      await _player.setAudioSources(
        sources,
        initialIndex: _currentPodcastIndex,
        initialPosition: Duration.zero,
      );
      if (_playbackSpeed != 1.0) {
        await _player.setSpeed(_playbackSpeed);
      }
      await _player.play();
    } catch (e) {
      debugPrint('Error playing podcast: $e');
      rethrow;
    }
  }

  Future<void> playPodcastEpisodeAtIndex(int index) async {
    if (index < 0 || index >= _podcastQueue.length) return;
    _currentPodcastIndex = index;
    _episodeChangeController.add(_podcastQueue[index]);

    try {
      await _player.seek(Duration.zero, index: index);
      if (!_player.playing) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('Error seeking podcast episode index: $e');
    }
  }

  Future<void> skipToNextPodcastEpisode() async {
    if (_podcastQueue.isEmpty) return;
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> skipToPreviousPodcastEpisode() async {
    if (_podcastQueue.isEmpty) return;
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  // ==========================================
  // SHARED PLAYBACK CONTROLS
  // ==========================================

  Future<void> playOrPause() async {
    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      debugPrint('playOrPause error: $e');
    }
  }

  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('play error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('pause error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _currentMode = AudioPlaybackMode.none;
      _modeController.add(_currentMode);
    } catch (e) {
      debugPrint('stop error: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('seek error: $e');
    }
  }

  Future<void> seekRelative(int seconds) async {
    final pos = _player.position;
    final dur = _player.duration ?? Duration.zero;
    final target = pos + Duration(seconds: seconds);
    final finalPos = target < Duration.zero
        ? Duration.zero
        : (target > dur && dur > Duration.zero ? dur : target);
    await seek(finalPos);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    try {
      await _player.setSpeed(speed);
    } catch (e) {
      debugPrint('setSpeed error: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('setVolume error: $e');
    }
  }
}
