import 'package:glitch_tv/features/home/domain/entities/podcast_entity.dart';

class PodcastDto {
  final int collectionId;
  final String collectionName;
  final String artistName;
  final String artworkUrl600;
  final String feedUrl;
  final int trackCount;
  final String primaryGenreName;

  PodcastDto({
    required this.collectionId,
    required this.collectionName,
    required this.artistName,
    required this.artworkUrl600,
    required this.feedUrl,
    required this.trackCount,
    required this.primaryGenreName,
  });

  factory PodcastDto.fromJson(Map<String, dynamic> json) {
    return PodcastDto(
      collectionId: (json['collectionId'] as num?)?.toInt() ??
          (json['trackId'] as num?)?.toInt() ??
          0,
      collectionName: (json['collectionName'] as String? ??
              json['trackName'] as String? ??
              '')
          .trim(),
      artistName: (json['artistName'] as String? ?? '').trim(),
      artworkUrl600: json['artworkUrl600'] as String? ??
          json['artworkUrl100'] as String? ??
          json['artworkUrl60'] as String? ??
          '',
      feedUrl: json['feedUrl'] as String? ?? '',
      trackCount: (json['trackCount'] as num?)?.toInt() ?? 0,
      primaryGenreName: json['primaryGenreName'] as String? ?? '',
    );
  }

  static List<PodcastDto> fromJsonList(List<dynamic> list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => PodcastDto.fromJson(j))
        .toList();
  }

  PodcastEntity toEntity() {
    return PodcastEntity(
      id: collectionId.toString(),
      name: collectionName,
      host: artistName,
      artworkUrl: artworkUrl600,
      feedUrl: feedUrl,
      episodesCount: trackCount,
      category: primaryGenreName,
    );
  }
}
