import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';

class LogosResponseDto {
  String? channel;
  String? feed;
  bool? inUse;
  List<String>? tags;
  int? width;
  int? height;
  String? format;
  String? url;

  LogosResponseDto({
    this.channel,
    this.feed,
    this.inUse,
    this.tags,
    this.width,
    this.height,
    this.format,
    this.url,
  });

  LogosResponseDto.fromJson(Map<String, dynamic> json) {
    channel = json['channel'];
    feed = json['feed'];
    inUse = json['in_use'];
    if (json['tags'] != null && json['tags'] is List) {
      tags = (json['tags'] as List).map((v) => v.toString()).toList();
    }
    width = json['width'];
    height = json['height'];
    format = json['format'];
    url = json['url'];
  }

  static List<LogosResponseDto> fromJsonList(
    List<dynamic> jsonList, {
    Set<String>? allowedChannelIds,
  }) {
    final lowerAllowed = allowedChannelIds?.map((e) => e.toLowerCase()).toSet();

    final List<LogosResponseDto> list = [];
    for (final item in jsonList) {
      if (item is! Map<String, dynamic>) continue;
      final ch = item['channel'] as String?;
      if (ch == null) continue;
      if (lowerAllowed != null && !lowerAllowed.contains(ch.toLowerCase())) {
        continue;
      }
      list.add(LogosResponseDto.fromJson(item));
    }
    return list;
  }

  LogosResponseEntity toEntity() {
    return LogosResponseEntity(
      channel: channel ?? '',
      feed: feed ?? '',
      inUse: inUse ?? false,
      tags: tags ?? const [],
      width: width ?? 0,
      height: height ?? 0,
      format: format ?? '',
      url: url ?? '',
    );
  }
}
