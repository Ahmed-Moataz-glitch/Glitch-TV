class DownloadedEpisodeDto {
  final String id;
  final String podcastId;
  final String podcastName;
  final String episodeTitle;
  final String audioUrl;
  final String localPath;
  final String artworkUrl;
  final String host;
  final String duration;
  final String pubDate;
  final String fileSize;
  final DateTime downloadedAt;

  DownloadedEpisodeDto({
    required this.id,
    required this.podcastId,
    required this.podcastName,
    required this.episodeTitle,
    required this.audioUrl,
    required this.localPath,
    required this.artworkUrl,
    required this.host,
    required this.duration,
    required this.pubDate,
    required this.fileSize,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'podcastId': podcastId,
      'podcastName': podcastName,
      'episodeTitle': episodeTitle,
      'audioUrl': audioUrl,
      'localPath': localPath,
      'artworkUrl': artworkUrl,
      'host': host,
      'duration': duration,
      'pubDate': pubDate,
      'fileSize': fileSize,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory DownloadedEpisodeDto.fromJson(Map<String, dynamic> json) {
    return DownloadedEpisodeDto(
      id: json['id'] as String? ?? '',
      podcastId: json['podcastId'] as String? ?? '',
      podcastName: json['podcastName'] as String? ?? '',
      episodeTitle: json['episodeTitle'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      localPath: json['localPath'] as String? ?? '',
      artworkUrl: json['artworkUrl'] as String? ?? '',
      host: json['host'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      pubDate: json['pubDate'] as String? ?? '',
      fileSize: json['fileSize'] as String? ?? '',
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  DownloadedEpisodeDto copyWith({
    String? id,
    String? podcastId,
    String? podcastName,
    String? episodeTitle,
    String? audioUrl,
    String? localPath,
    String? artworkUrl,
    String? host,
    String? duration,
    String? pubDate,
    String? fileSize,
    DateTime? downloadedAt,
  }) {
    return DownloadedEpisodeDto(
      id: id ?? this.id,
      podcastId: podcastId ?? this.podcastId,
      podcastName: podcastName ?? this.podcastName,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      audioUrl: audioUrl ?? this.audioUrl,
      localPath: localPath ?? this.localPath,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      host: host ?? this.host,
      duration: duration ?? this.duration,
      pubDate: pubDate ?? this.pubDate,
      fileSize: fileSize ?? this.fileSize,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }
}
