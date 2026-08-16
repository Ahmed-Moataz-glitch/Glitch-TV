import 'dart:convert';

import 'package:glitch_tv/features/home/domain/entities/logos_response_entity.dart';

class LogosResponseDto {
  String? channel;
  bool? inUse;
  int? width;
  int? height;
  String? format;
  String? url;

  LogosResponseDto({
    this.channel,
    this.inUse,
    this.width,
    this.height,
    this.format,
    this.url,
  });

  LogosResponseDto.fromJson(Map<String, dynamic> json) {
    channel = json['channel'];
    inUse = json['in_use'];
    width = json['width'];
    height = json['height'];
    format = json['format'];
    url = json['url'];
  }

  LogosResponseEntity toEntity() {
    return LogosResponseEntity(
      channel: jsonDecode(channel ?? ''),
      inUse: jsonDecode(inUse.toString()),
      width: jsonDecode(width.toString()),
      height: jsonDecode(height.toString()),
      format: jsonDecode(format ?? ''),
      url: jsonDecode(url ?? ''),
    );
  }
}
