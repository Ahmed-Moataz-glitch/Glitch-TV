import 'package:glitch_tv/features/channel_details/domain/entities/channel_stream_entity.dart';

class ChannelStreamDto {
  final String? channel;
  final String? feed;
  final String? title;
  final String url;
  final String? quality;
  final String? label;
  final String? userAgent;
  final String? referrer;

  const ChannelStreamDto({
    this.channel,
    this.feed,
    this.title,
    required this.url,
    this.quality,
    this.label,
    this.userAgent,
    this.referrer,
  });

  factory ChannelStreamDto.fromJson(Map<String, dynamic> json) {
    return ChannelStreamDto(
      channel: json['channel'] as String?,
      feed: json['feed'] as String?,
      title: json['title'] as String?,
      url: (json['url'] as String?) ?? '',
      quality: json['quality'] as String?,
      label: json['label'] as String?,
      userAgent: json['user_agent'] as String?,
      referrer: json['referrer'] as String?,
    );
  }

  static List<ChannelStreamDto> fromJsonList(
    List<dynamic> jsonList, {
    Set<String>? allowedChannelIds,
  }) {
    final Set<String>? normalizedAllowed = allowedChannelIds
        ?.map((id) => id.toLowerCase().trim())
        .toSet();

    return jsonList
        .whereType<Map<String, dynamic>>()
        .where((json) {
          final url = json['url'] as String?;
          if (url == null || url.trim().isEmpty) return false;

          if (normalizedAllowed == null || normalizedAllowed.isEmpty) {
            return true;
          }

          final channelId = (json['channel'] as String?)?.toLowerCase().trim();
          if (channelId == null) return false;
          if (normalizedAllowed.contains(channelId)) return true;
          final prefix = channelId.split('.').first;
          return normalizedAllowed.any((allowed) => allowed.split('.').first == prefix);
        })
        .map((json) => ChannelStreamDto.fromJson(json))
        .toList();
  }

  ChannelStreamEntity toEntity() {
    return ChannelStreamEntity(
      channelId: channel,
      feed: feed,
      title: title ?? '',
      url: url,
      quality: quality,
      label: label,
      userAgent: userAgent,
      referrer: referrer,
    );
  }
}
