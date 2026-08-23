import 'dart:convert';
import 'dart:isolate';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/features/podcast_details/data/models/podcast_episode_dto.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class PodcastDetailsApi {
  static final Map<String, List<PodcastEpisodeDto>> _cache = {};

  static void clearCache() {
    _cache.clear();
  }

  Future<ApiResult<List<PodcastEpisodeDto>>> fetchEpisodes({
    required String feedUrl,
    String fallbackArtwork = '',
    bool forceRefresh = false,
  }) async {
    if (feedUrl.trim().isEmpty) {
      return ApiError('Podcast feed URL is missing');
    }

    if (!forceRefresh && _cache.containsKey(feedUrl)) {
      final cached = _cache[feedUrl];
      if (cached != null && cached.isNotEmpty) {
        return ApiSuccess(cached);
      }
    }

    try {
      final response = await http.get(
        Uri.parse(feedUrl),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept':
              'application/rss+xml, application/xml, text/xml, application/atom+xml, */*',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        if (_cache.containsKey(feedUrl) && _cache[feedUrl]!.isNotEmpty) {
          return ApiSuccess(_cache[feedUrl]!);
        }
        return ApiError('Failed to fetch podcast feed (${response.statusCode})');
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
        _cache[feedUrl] = dtos;
      } else if (_cache.containsKey(feedUrl) && _cache[feedUrl]!.isNotEmpty) {
        return ApiSuccess(_cache[feedUrl]!);
      }

      return ApiSuccess(dtos);
    } catch (e) {
      if (_cache.containsKey(feedUrl) && _cache[feedUrl]!.isNotEmpty) {
        return ApiSuccess(_cache[feedUrl]!);
      }
      return ApiError('Failed to load episodes: ${e.toString()}');
    }
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
