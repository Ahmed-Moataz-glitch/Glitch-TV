class PodcastEpisodeEntity {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String duration;
  final String pubDate;
  final String artworkUrl;
  final String episodeNumber;

  const PodcastEpisodeEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.duration,
    required this.pubDate,
    this.artworkUrl = '',
    this.episodeNumber = '',
  });
}
