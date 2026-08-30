import 'dart:convert';
import 'dart:isolate';
import 'package:glitch_tv/core/services/api_cache_service.dart';
import 'package:glitch_tv/core/services/app_http_client.dart';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/core/utils/app_api.dart';
import 'package:glitch_tv/features/home/data/models/channels_model.dart';
import 'package:glitch_tv/features/home/data/models/channels_response_dto.dart';
import 'package:glitch_tv/features/home/data/models/logos_response_dto.dart';
import 'package:glitch_tv/features/home/data/models/podcast_dto.dart';
import 'package:glitch_tv/features/home/data/models/radio_station_dto.dart';

class HomeApi {
  static List<LogosResponseDto>? _memoryLogos;
  static List<ChannelsResponseDto>? _memoryChannels;
  static List<RadioStationDto>? _memoryRadioStations;
  static List<PodcastDto>? _memoryPodcasts;

  static const String _logosCacheKey = 'home_logos_cache';
  static const String _channelsCacheKey = 'home_channels_cache';
  static const String _radioCacheKey = 'home_radio_cache';
  static const String _podcastsCacheKey = 'home_podcasts_cache';

  static const Duration _logosTtl = Duration(hours: 48);
  static const Duration _channelsTtl = Duration(hours: 48);
  static const Duration _radioTtl = Duration(hours: 24);
  static const Duration _podcastsTtl = Duration(hours: 12);

  static void clearMemoryCache() {
    _memoryLogos = null;
    _memoryChannels = null;
    _memoryRadioStations = null;
    _memoryPodcasts = null;
  }

  Future<ApiResult<List<LogosResponseDto>>> fetchLogos({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryLogos != null && _memoryLogos!.isNotEmpty) {
      return ApiSuccess(_memoryLogos!);
    }

    final allowedSet = channels.toSet();

    if (!forceRefresh) {
      final cachedJson = await ApiCacheService.instance.get(_logosCacheKey, maxAge: _logosTtl);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final dtos = await Isolate.run(() {
            final jsonList = jsonDecode(cachedJson) as List<dynamic>;
            return LogosResponseDto.fromJsonList(jsonList, allowedChannelIds: allowedSet);
          });
          if (dtos.isNotEmpty) {
            _memoryLogos = dtos;
            return ApiSuccess(dtos);
          }
        } catch (_) {}
      }
    }

    final url = Uri.https(AppApi.iptvBaseUrl, AppApi.logosEndpoint);
    try {
      final response = await AppHttpClient.client
          .get(url, headers: AppHttpClient.defaultHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return await _fallbackLogos(allowedSet, 'Failed to fetch logos (${response.statusCode})');
      }

      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      final dtos = await Isolate.run(() {
        final jsonList = jsonDecode(text) as List<dynamic>;
        return LogosResponseDto.fromJsonList(jsonList, allowedChannelIds: allowedSet);
      });

      if (dtos.isNotEmpty) {
        _memoryLogos = dtos;
        await ApiCacheService.instance.put(_logosCacheKey, text);
      }

      return ApiSuccess(dtos);
    } catch (e) {
      return await _fallbackLogos(allowedSet, 'Logos network error: ${e.toString()}');
    }
  }

  Future<ApiResult<List<LogosResponseDto>>> _fallbackLogos(Set<String> allowedSet, String errorMsg) async {
    if (_memoryLogos != null && _memoryLogos!.isNotEmpty) {
      return ApiSuccess(_memoryLogos!);
    }
    final fallback = await ApiCacheService.instance.getFallback(_logosCacheKey);
    if (fallback != null && fallback.isNotEmpty) {
      try {
        final dtos = await Isolate.run(() {
          final jsonList = jsonDecode(fallback) as List<dynamic>;
          return LogosResponseDto.fromJsonList(jsonList, allowedChannelIds: allowedSet);
        });
        if (dtos.isNotEmpty) {
          _memoryLogos = dtos;
          return ApiSuccess(dtos);
        }
      } catch (_) {}
    }
    return ApiError(errorMsg);
  }

  Future<ApiResult<List<ChannelsResponseDto>>> fetchChannels({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryChannels != null && _memoryChannels!.isNotEmpty) {
      return ApiSuccess(_memoryChannels!);
    }

    final allowedSet = channels.toSet();

    if (!forceRefresh) {
      final cachedJson = await ApiCacheService.instance.get(_channelsCacheKey, maxAge: _channelsTtl);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final dtos = await Isolate.run(() {
            final jsonList = jsonDecode(cachedJson) as List<dynamic>;
            return ChannelsResponseDto.fromJsonList(jsonList, allowedChannelIds: allowedSet);
          });
          if (dtos.isNotEmpty) {
            _memoryChannels = dtos;
            return ApiSuccess(dtos);
          }
        } catch (_) {}
      }
    }

    final url = Uri.https(AppApi.iptvBaseUrl, AppApi.channelsEndpoint);
    try {
      final response = await AppHttpClient.client
          .get(url, headers: AppHttpClient.defaultHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return await _fallbackChannels(allowedSet, 'Failed to fetch channels (${response.statusCode})');
      }

      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      final dtos = await Isolate.run(() {
        final jsonList = jsonDecode(text) as List<dynamic>;
        return ChannelsResponseDto.fromJsonList(jsonList, allowedChannelIds: allowedSet);
      });

      if (dtos.isNotEmpty) {
        _memoryChannels = dtos;
        await ApiCacheService.instance.put(_channelsCacheKey, text);
      }

      return ApiSuccess(dtos);
    } catch (e) {
      return await _fallbackChannels(allowedSet, 'Channels network error: ${e.toString()}');
    }
  }

  Future<ApiResult<List<ChannelsResponseDto>>> _fallbackChannels(Set<String> allowedSet, String errorMsg) async {
    if (_memoryChannels != null && _memoryChannels!.isNotEmpty) {
      return ApiSuccess(_memoryChannels!);
    }
    final fallback = await ApiCacheService.instance.getFallback(_channelsCacheKey);
    if (fallback != null && fallback.isNotEmpty) {
      try {
        final dtos = await Isolate.run(() {
          final jsonList = jsonDecode(fallback) as List<dynamic>;
          return ChannelsResponseDto.fromJsonList(jsonList, allowedChannelIds: allowedSet);
        });
        if (dtos.isNotEmpty) {
          _memoryChannels = dtos;
          return ApiSuccess(dtos);
        }
      } catch (_) {}
    }
    return ApiError(errorMsg);
  }

  Future<ApiResult<List<RadioStationDto>>> fetchRadioStations({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryRadioStations != null && _memoryRadioStations!.isNotEmpty) {
      return ApiSuccess(_memoryRadioStations!);
    }

    if (!forceRefresh) {
      final cachedJson = await ApiCacheService.instance.get(_radioCacheKey, maxAge: _radioTtl);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final dtos = await Isolate.run(() {
            final decoded = jsonDecode(cachedJson);
            final List<dynamic> jsonList;
            if (decoded is List) {
              jsonList = decoded;
            } else if (decoded is Map<String, dynamic>) {
              jsonList = decoded['results'] as List<dynamic>? ?? [];
            } else {
              jsonList = [];
            }
            return RadioStationDto.fromJsonList(jsonList);
          });
          if (dtos.isNotEmpty) {
            _memoryRadioStations = dtos;
            return ApiSuccess(dtos);
          }
        } catch (_) {}
      }
    }

    final url = Uri.https(AppApi.radioBaseUrl, AppApi.radioStationsEndpoint);
    try {
      final response = await AppHttpClient.client
          .get(url, headers: AppHttpClient.defaultHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return await _fallbackRadio('Failed to fetch radio stations (${response.statusCode})');
      }

      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      final dtos = await Isolate.run(() {
        final decoded = jsonDecode(text);
        final List<dynamic> jsonList;
        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          jsonList = decoded['results'] as List<dynamic>? ?? [];
        } else {
          jsonList = [];
        }
        return RadioStationDto.fromJsonList(jsonList);
      });

      if (dtos.isNotEmpty) {
        _memoryRadioStations = dtos;
        await ApiCacheService.instance.put(_radioCacheKey, text);
      }

      return ApiSuccess(dtos);
    } catch (e) {
      return await _fallbackRadio('Radio stations network error: ${e.toString()}');
    }
  }

  Future<ApiResult<List<RadioStationDto>>> _fallbackRadio(String errorMsg) async {
    if (_memoryRadioStations != null && _memoryRadioStations!.isNotEmpty) {
      return ApiSuccess(_memoryRadioStations!);
    }
    final fallback = await ApiCacheService.instance.getFallback(_radioCacheKey);
    if (fallback != null && fallback.isNotEmpty) {
      try {
        final dtos = await Isolate.run(() {
          final decoded = jsonDecode(fallback);
          final List<dynamic> jsonList;
          if (decoded is List) {
            jsonList = decoded;
          } else if (decoded is Map<String, dynamic>) {
            jsonList = decoded['results'] as List<dynamic>? ?? [];
          } else {
            jsonList = [];
          }
          return RadioStationDto.fromJsonList(jsonList);
        });
        if (dtos.isNotEmpty) {
          _memoryRadioStations = dtos;
          return ApiSuccess(dtos);
        }
      } catch (_) {}
    }
    return ApiError(errorMsg);
  }

  Future<ApiResult<List<PodcastDto>>> fetchPodcasts({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryPodcasts != null && _memoryPodcasts!.isNotEmpty) {
      return ApiSuccess(_memoryPodcasts!);
    }

    if (!forceRefresh) {
      final cachedJson = await ApiCacheService.instance.get(_podcastsCacheKey, maxAge: _podcastsTtl);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final dtos = await Isolate.run(() {
            final decoded = jsonDecode(cachedJson);
            final List<dynamic> jsonList;
            if (decoded is Map<String, dynamic>) {
              jsonList = decoded['results'] as List<dynamic>? ?? [];
            } else if (decoded is List) {
              jsonList = decoded;
            } else {
              jsonList = [];
            }
            return PodcastDto.fromJsonList(jsonList);
          });
          if (dtos.isNotEmpty) {
            _memoryPodcasts = dtos;
            return ApiSuccess(dtos);
          }
        } catch (_) {}
      }
    }

    final url = Uri.https(AppApi.podcastsBaseUrl, AppApi.podcastsEndpoint, {
      'id': AppApi.podcastsIds,
    });
    try {
      final response = await AppHttpClient.client
          .get(url, headers: AppHttpClient.defaultHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return await _fallbackPodcasts('Failed to fetch podcasts (${response.statusCode})');
      }

      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      final dtos = await Isolate.run(() {
        final decoded = jsonDecode(text);
        final List<dynamic> jsonList;
        if (decoded is Map<String, dynamic>) {
          jsonList = decoded['results'] as List<dynamic>? ?? [];
        } else if (decoded is List) {
          jsonList = decoded;
        } else {
          jsonList = [];
        }
        return PodcastDto.fromJsonList(jsonList);
      });

      if (dtos.isNotEmpty) {
        _memoryPodcasts = dtos;
        await ApiCacheService.instance.put(_podcastsCacheKey, text);
      }

      return ApiSuccess(dtos);
    } catch (e) {
      return await _fallbackPodcasts('Podcasts network error: ${e.toString()}');
    }
  }

  Future<ApiResult<List<PodcastDto>>> _fallbackPodcasts(String errorMsg) async {
    if (_memoryPodcasts != null && _memoryPodcasts!.isNotEmpty) {
      return ApiSuccess(_memoryPodcasts!);
    }
    final fallback = await ApiCacheService.instance.getFallback(_podcastsCacheKey);
    if (fallback != null && fallback.isNotEmpty) {
      try {
        final dtos = await Isolate.run(() {
          final decoded = jsonDecode(fallback);
          final List<dynamic> jsonList;
          if (decoded is Map<String, dynamic>) {
            jsonList = decoded['results'] as List<dynamic>? ?? [];
          } else if (decoded is List) {
            jsonList = decoded;
          } else {
            jsonList = [];
          }
          return PodcastDto.fromJsonList(jsonList);
        });
        if (dtos.isNotEmpty) {
          _memoryPodcasts = dtos;
          return ApiSuccess(dtos);
        }
      } catch (_) {}
    }
    return ApiError(errorMsg);
  }
}
