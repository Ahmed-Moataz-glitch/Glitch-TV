import 'dart:convert';
import 'dart:isolate';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/core/utils/app_api.dart';
import 'package:glitch_tv/features/channel_details/data/models/channel_stream_dto.dart';
import 'package:glitch_tv/features/channel_details/data/models/epg_programme_dto.dart';
import 'package:glitch_tv/features/home/data/models/channels_model.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class ChannelDetailsApi {
  static List<EpgProgrammeDto>? _cachedEpg;
  static DateTime? _lastFetchTime;
  static List<ChannelStreamDto>? _cachedStreams;

  static void clearCache() {
    _cachedEpg = null;
    _lastFetchTime = null;
    _cachedStreams = null;
  }

  Future<ApiResult<List<EpgProgrammeDto>>> fetchEpgGuide({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && _cachedEpg != null && _lastFetchTime != null) {
      final isSameDay = _lastFetchTime!.year == now.year &&
          _lastFetchTime!.month == now.month &&
          _lastFetchTime!.day == now.day;
      if (isSameDay) {
        return ApiSuccess(_cachedEpg!);
      }
    }

    final url = Uri.https(AppApi.epgBaseUrl, AppApi.epgGuideEndpoint);
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        if (_cachedEpg != null && _cachedEpg!.isNotEmpty) {
          return ApiSuccess(_cachedEpg!);
        }
        return ApiError('Failed to fetch EPG guide (${response.statusCode})');
      }

      final responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);

      // Detect Open-EPG daily rate limit HTML response
      if (responseBody.contains('reached the download limit') ||
          responseBody.contains('download limit for this file')) {
        if (_cachedEpg != null && _cachedEpg!.isNotEmpty) {
          return ApiSuccess(_cachedEpg!);
        }
        return ApiError(
            'Reached daily EPG download limit (30 requests/day). Please try again tomorrow.');
      }

      final dtos = await Isolate.run(() {
        return parseXmlContent(responseBody);
      });

      if (dtos.isNotEmpty) {
        _cachedEpg = dtos;
        _lastFetchTime = DateTime.now();
      } else if (_cachedEpg != null && _cachedEpg!.isNotEmpty) {
        return ApiSuccess(_cachedEpg!);
      }

      return ApiSuccess(dtos);
    } catch (e) {
      if (_cachedEpg != null && _cachedEpg!.isNotEmpty) {
        return ApiSuccess(_cachedEpg!);
      }
      return ApiError('EPG network error: ${e.toString()}');
    }
  }

  Future<ApiResult<List<ChannelStreamDto>>> fetchStreams({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedStreams != null && _cachedStreams!.isNotEmpty) {
      return ApiSuccess(_cachedStreams!);
    }

    final url = Uri.https(AppApi.iptvBaseUrl, AppApi.streamsEndpoint);
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        if (_cachedStreams != null && _cachedStreams!.isNotEmpty) {
          return ApiSuccess(_cachedStreams!);
        }
        return ApiError('Failed to fetch streams (${response.statusCode})');
      }

      final responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      final allowedSet = channels.toSet();
      final dtos = await Isolate.run(() {
        final jsonList = jsonDecode(responseBody) as List<dynamic>;
        return ChannelStreamDto.fromJsonList(jsonList, allowedChannelIds: allowedSet);
      });

      _cachedStreams = dtos;
      return ApiSuccess(dtos);
    } catch (e) {
      if (_cachedStreams != null && _cachedStreams!.isNotEmpty) {
        return ApiSuccess(_cachedStreams!);
      }
      return ApiError('Streams network error: ${e.toString()}');
    }
  }

  static List<EpgProgrammeDto> parseXmlContent(String rawXml) {
    final cleanXml = _sanitizeXml(rawXml);
    try {
      final document = XmlDocument.parse(cleanXml);
      final programmeElements = document.findAllElements('programme');
      return programmeElements
          .map((element) => EpgProgrammeDto.fromXmlElement(element))
          .toList();
    } catch (_) {
      return _parseWithRegExp(rawXml);
    }
  }

  static String _sanitizeXml(String input) {
    var xml = input;
    if (xml.startsWith('\uFEFF')) {
      xml = xml.substring(1);
    }
    xml = xml.trim();

    final xmlIdx = xml.indexOf('<?xml');
    final tvIdx = xml.indexOf('<tv');
    if (xmlIdx != -1) {
      xml = xml.substring(xmlIdx);
    } else if (tvIdx != -1) {
      xml = xml.substring(tvIdx);
    }

    xml = xml.replaceAll(
      RegExp(r'&(?!(amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)'),
      '&amp;',
    );

    return xml;
  }

  static List<EpgProgrammeDto> _parseWithRegExp(String xml) {
    final programmeRegex = RegExp(
      r'<programme\s+([^>]*)\bchannel="([^"]+)"([^>]*)>(.*?)</programme>',
      dotAll: true,
    );
    final startRegex = RegExp(r'\bstart="([^"]+)"');
    final stopRegex = RegExp(r'\bstop="([^"]+)"');
    final titleRegex = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true);
    final subTitleRegex = RegExp(r'<sub-title[^>]*>(.*?)</sub-title>', dotAll: true);
    final descRegex = RegExp(r'<desc[^>]*>(.*?)</desc>', dotAll: true);

    final List<EpgProgrammeDto> list = [];

    for (final match in programmeRegex.allMatches(xml)) {
      final attrText = '${match.group(1)} ${match.group(3)}';
      final channel = match.group(2) ?? '';
      final body = match.group(4) ?? '';

      final startMatch = startRegex.firstMatch(attrText);
      final stopMatch = stopRegex.firstMatch(attrText);
      final titleMatch = titleRegex.firstMatch(body);
      final subTitleMatch = subTitleRegex.firstMatch(body);
      final descMatch = descRegex.firstMatch(body);

      final start = startMatch?.group(1) ?? '';
      final stop = stopMatch?.group(1) ?? '';
      final title = _cleanText(titleMatch?.group(1) ?? '');
      final subTitle = _cleanText(subTitleMatch?.group(1) ?? '');
      final desc = _cleanText(descMatch?.group(1) ?? '');

      list.add(EpgProgrammeDto(
        channel: channel,
        start: start,
        stop: stop,
        title: title,
        subTitle: subTitle,
        desc: desc,
      ));
    }

    return list;
  }

  static String _cleanText(String s) {
    return s
        .replaceAll('<![CDATA[', '')
        .replaceAll(']]>', '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .trim();
  }
}
