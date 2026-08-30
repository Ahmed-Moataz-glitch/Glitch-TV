import 'dart:convert';
import 'dart:isolate';
import 'package:glitch_tv/core/services/api_cache_service.dart';
import 'package:glitch_tv/core/services/app_http_client.dart';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/podcast_details/data/models/podcast_episode_dto.dart';
import 'package:xml/xml.dart';

class PodcastDetailsApi {
  static final Map<String, List<PodcastEpisodeDto>> _cache = {};
  static const Duration _episodesTtl = Duration(hours: 6);

  static void clearCache() {
    _cache.clear();
  }

  String _cacheKey(String feedUrl) => 'podcast_feed_${feedUrl.trim().toLowerCase()}';

  Future<ApiResult<List<PodcastEpisodeDto>>> fetchEpisodes({
    required String feedUrl,
    String fallbackArtwork = '',
    bool forceRefresh = false,
  }) async {
    final cleanUrl = feedUrl.trim();
    if (cleanUrl.isEmpty) {
      return ApiError('Podcast feed URL is missing');
    }

    if (!forceRefresh && _cache.containsKey(cleanUrl)) {
      final cached = _cache[cleanUrl];
      if (cached != null && cached.isNotEmpty) {
        return ApiSuccess(cached);
      }
    }

    final key = _cacheKey(cleanUrl);

    if (!forceRefresh) {
      final cachedXml = await ApiCacheService.instance.get(key, maxAge: _episodesTtl);
      if (cachedXml != null && cachedXml.isNotEmpty) {
        try {
          final dtos = await Isolate.run(() {
            final clean = _sanitizeXml(cachedXml);
            final document = XmlDocument.parse(clean);
            return PodcastEpisodeDto.fromXmlDocument(
              document,
              fallbackArtwork: fallbackArtwork,
            );
          });
          if (dtos.isNotEmpty) {
            _cache[cleanUrl] = dtos;
            return ApiSuccess(dtos);
          }
        } catch (_) {}
      }
    }

    try {
      final response = await AppHttpClient.client.get(
        Uri.parse(cleanUrl),
        headers: {
          ...AppHttpClient.defaultHeaders,
          'Accept':
              'application/rss+xml, application/xml, text/xml, application/atom+xml, */*',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return await _fallbackEpisodes(cleanUrl, key, fallbackArtwork, 'Failed to fetch podcast feed (${response.statusCode})');
      }

      final responseBody = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );

      final dtos = await Isolate.run(() {
        final cleanXml = _sanitizeXml(responseBody);
        final document = XmlDocument.parse(cleanXml);
        return PodcastEpisodeDto.fromXmlDocument(
          document,
          fallbackArtwork: fallbackArtwork,
        );
      });

      if (dtos.isNotEmpty) {
        _cache[cleanUrl] = dtos;
        await ApiCacheService.instance.put(key, responseBody);
      }

      return ApiSuccess(dtos);
    } catch (e) {
      return await _fallbackEpisodes(cleanUrl, key, fallbackArtwork, 'Failed to load episodes: ${e.toString()}');
    }
  }

  Future<ApiResult<List<PodcastEpisodeDto>>> _fallbackEpisodes(
    String feedUrl,
    String key,
    String fallbackArtwork,
    String errorMsg,
  ) async {
    if (_cache.containsKey(feedUrl) && _cache[feedUrl]!.isNotEmpty) {
      return ApiSuccess(_cache[feedUrl]!);
    }
    final fallback = await ApiCacheService.instance.getFallback(key);
    if (fallback != null && fallback.isNotEmpty) {
      try {
        final dtos = await Isolate.run(() {
          final cleanXml = _sanitizeXml(fallback);
          final document = XmlDocument.parse(cleanXml);
          return PodcastEpisodeDto.fromXmlDocument(
            document,
            fallbackArtwork: fallbackArtwork,
          );
        });
        if (dtos.isNotEmpty) {
          _cache[feedUrl] = dtos;
          return ApiSuccess(dtos);
        }
      } catch (_) {}
    }
    return ApiError(errorMsg);
  }

  static String _sanitizeXml(String input) {
    var xml = input;
    if (xml.startsWith('\uFEFF')) {
      xml = xml.substring(1);
    }
    xml = xml.trim();

    final xmlIdx = xml.indexOf('<?xml');
    final rssIdx = xml.indexOf('<rss');
    final feedIdx = xml.indexOf('<feed');

    if (xmlIdx != -1) {
      xml = xml.substring(xmlIdx);
    } else if (rssIdx != -1) {
      xml = xml.substring(rssIdx);
    } else if (feedIdx != -1) {
      xml = xml.substring(feedIdx);
    }

    xml = xml.replaceAll(
      RegExp(r'&(?!(amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)'),
      '&amp;',
    );

    return xml;
  }
}
