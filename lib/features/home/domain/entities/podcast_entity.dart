class PodcastEntity {
  final String id;
  final String name;
  final String host;
  final String artworkUrl;
  final String feedUrl;
  final int episodesCount;
  final String category;

  const PodcastEntity({
    required this.id,
    required this.name,
    required this.host,
    required this.artworkUrl,
    required this.feedUrl,
    required this.episodesCount,
    required this.category,
  });
}
