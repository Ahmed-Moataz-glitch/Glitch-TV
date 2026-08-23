class RadioStationEntity {
  final String id;
  final String name;
  final String streamUrl;
  final String favicon;
  final String tags;
  final String country;
  final String state;
  final String language;
  final int votes;

  RadioStationEntity({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.favicon,
    required this.tags,
    required this.country,
    required this.state,
    required this.language,
    required this.votes,
  });
}
