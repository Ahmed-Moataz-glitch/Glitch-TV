import 'package:glitch_tv/features/channel_details/domain/entities/epg_programme_entity.dart';
import 'package:xml/xml.dart';

class EpgProgrammeDto {
  final String channel;
  final String start;
  final String stop;
  final String title;
  final String subTitle;
  final String desc;

  EpgProgrammeDto({
    required this.channel,
    required this.start,
    required this.stop,
    required this.title,
    required this.subTitle,
    required this.desc,
  });

  factory EpgProgrammeDto.fromXmlElement(XmlElement element) {
    final channel = element.getAttribute('channel') ?? '';
    final start = element.getAttribute('start') ?? '';
    final stop = element.getAttribute('stop') ?? '';
    final title = element.findElements('title').firstOrNull?.innerText ?? '';
    final subTitle = element.findElements('sub-title').firstOrNull?.innerText ?? '';
    final desc = element.findElements('desc').firstOrNull?.innerText ?? '';

    return EpgProgrammeDto(
      channel: channel,
      start: start,
      stop: stop,
      title: title,
      subTitle: subTitle,
      desc: desc,
    );
  }

  EpgProgrammeEntity toEntity() {
    return EpgProgrammeEntity(
      channelId: channel,
      title: title,
      subTitle: subTitle,
      description: desc,
      startTime: parseEpgDate(start),
      stopTime: parseEpgDate(stop),
      startRaw: start,
      stopRaw: stop,
    );
  }

  static DateTime? parseEpgDate(String raw) {
    if (raw.trim().length < 14) return null;
    try {
      final clean = raw.trim();
      final year = int.parse(clean.substring(0, 4));
      final month = int.parse(clean.substring(4, 6));
      final day = int.parse(clean.substring(6, 8));
      final hour = int.parse(clean.substring(8, 10));
      final minute = int.parse(clean.substring(10, 12));
      final second = int.parse(clean.substring(12, 14));

      int offsetMinutes = 0;
      final spaceIndex = clean.indexOf(' ');
      if (spaceIndex != -1 && spaceIndex < clean.length - 1) {
        final offsetStr = clean.substring(spaceIndex + 1).trim();
        if (offsetStr.length >= 5) {
          final sign = offsetStr[0] == '-' ? -1 : 1;
          final h = int.tryParse(offsetStr.substring(1, 3)) ?? 0;
          final m = int.tryParse(offsetStr.substring(3, 5)) ?? 0;
          offsetMinutes = sign * (h * 60 + m);
        }
      }

      final utcDate = DateTime.utc(year, month, day, hour, minute, second);
      return utcDate.subtract(Duration(minutes: offsetMinutes)).toLocal();
    } catch (_) {
      return null;
    }
  }
}
