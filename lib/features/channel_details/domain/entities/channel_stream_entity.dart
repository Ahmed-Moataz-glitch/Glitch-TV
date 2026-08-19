class ChannelStreamEntity {
  final String? channelId;
  final String? feed;
  final String title;
  final String url;
  final String? quality;
  final String? label;
  final String? userAgent;
  final String? referrer;

  const ChannelStreamEntity({
    this.channelId,
    this.feed,
    required this.title,
    required this.url,
    this.quality,
    this.label,
    this.userAgent,
    this.referrer,
  });
}
