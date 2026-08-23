import 'package:glitch_tv/features/home/domain/entities/radio_station_entity.dart';

class RadioStationDto {
  final String stationUuid;
  final String name;
  final String url;
  final String urlResolved;
  final String favicon;
  final String tags;
  final String country;
  final String state;
  final String language;
  final int votes;

  RadioStationDto({
    required this.stationUuid,
    required this.name,
    required this.url,
    required this.urlResolved,
    required this.favicon,
    required this.tags,
    required this.country,
    required this.state,
    required this.language,
    required this.votes,
  });

  factory RadioStationDto.fromJson(Map<String, dynamic> json) {
    return RadioStationDto(
      stationUuid: json['stationuuid'] as String? ?? '',
      name: (json['name'] as String? ?? '').trim(),
      url: json['url'] as String? ?? '',
      urlResolved: json['url_resolved'] as String? ?? '',
      favicon: json['favicon'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      country: json['country'] as String? ?? '',
      state: json['state'] as String? ?? '',
      language: json['language'] as String? ?? '',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
    );
  }

  static List<RadioStationDto> fromJsonList(List<dynamic> list) {
    final rawStations = list
        .whereType<Map<String, dynamic>>()
        .map((j) => RadioStationDto.fromJson(j))
        .where((s) =>
            s.name.trim().isNotEmpty &&
            (s.url.isNotEmpty || s.urlResolved.isNotEmpty))
        .toList();

    // Prioritize stations with favicon and higher votes
    rawStations.sort((a, b) {
      final aHasFavicon = a.favicon.isNotEmpty ? 1 : 0;
      final bHasFavicon = b.favicon.isNotEmpty ? 1 : 0;
      if (aHasFavicon != bHasFavicon) {
        return bHasFavicon.compareTo(aHasFavicon);
      }
      return b.votes.compareTo(a.votes);
    });

    final List<RadioStationDto> uniqueStations = [];
    final Set<String> seenNormalizedNames = {};
    final Set<String> seenUrls = {};
    final Set<String> seenUuids = {};

    for (final station in rawStations) {
      if (station.stationUuid.isNotEmpty &&
          seenUuids.contains(station.stationUuid)) {
        continue;
      }

      final normName = _normalizeStationName(station.name);
      final normUrl = _normalizeUrl(
          station.urlResolved.isNotEmpty ? station.urlResolved : station.url);

      if (normName.isNotEmpty && seenNormalizedNames.contains(normName)) {
        continue;
      }
      if (normUrl.isNotEmpty && seenUrls.contains(normUrl)) {
        continue;
      }

      if (station.stationUuid.isNotEmpty) seenUuids.add(station.stationUuid);
      if (normName.isNotEmpty) seenNormalizedNames.add(normName);
      if (normUrl.isNotEmpty) seenUrls.add(normUrl);

      uniqueStations.add(station);
    }

    return uniqueStations;
  }

  static String _normalizeStationName(String name) {
    var normalized = name.toLowerCase().trim();

    // Remove Arabic diacritics / tashkeel
    normalized =
        normalized.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // Normalize Arabic characters
    normalized = normalized
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');

    // Remove punctuation, brackets, and symbols
    normalized = normalized.replaceAll(
        RegExp(r'[\.,\-_/\\|:;()\[\]{}!@#$%^&*+=~`<>"?]'), ' ');

    // Normalize multiple spaces into single space
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  static String _normalizeUrl(String url) {
    var normalized = url.trim().toLowerCase();
    normalized = normalized.replaceFirst(RegExp(r'^https?:\/\/'), '');
    final queryIdx = normalized.indexOf('?');
    if (queryIdx != -1) {
      normalized = normalized.substring(0, queryIdx);
    }
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  RadioStationEntity toEntity() {
    final streamUrl = urlResolved.isNotEmpty ? urlResolved : url;
    return RadioStationEntity(
      id: stationUuid,
      name: name,
      streamUrl: streamUrl,
      favicon: favicon,
      tags: tags,
      country: country,
      state: state,
      language: language,
      votes: votes,
    );
  }
}
