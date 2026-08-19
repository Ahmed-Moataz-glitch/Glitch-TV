class EpgProgrammeEntity {
  final String channelId;
  final String title;
  final String subTitle;
  final String description;
  final DateTime? startTime;
  final DateTime? stopTime;
  final String startRaw;
  final String stopRaw;

  EpgProgrammeEntity({
    required this.channelId,
    required this.title,
    required this.subTitle,
    required this.description,
    this.startTime,
    this.stopTime,
    required this.startRaw,
    required this.stopRaw,
  });

  bool get isLive {
    if (startTime == null || stopTime == null) return false;
    final now = DateTime.now();
    return now.isAfter(startTime!) && now.isBefore(stopTime!);
  }

  bool get isPast {
    if (stopTime == null) return false;
    return stopTime!.isBefore(DateTime.now());
  }

  bool get isUpcoming {
    if (startTime == null) return false;
    return startTime!.isAfter(DateTime.now());
  }

  bool get isToday {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (startTime != null && stopTime != null) {
      return stopTime!.isAfter(startOfDay) && startTime!.isBefore(endOfDay);
    }
    if (startTime != null) {
      return startTime!.year == now.year &&
          startTime!.month == now.month &&
          startTime!.day == now.day;
    }
    return false;
  }

  String get formattedTime {
    if (startTime == null) return '';
    final startStr = _formatTimeOfDay(startTime!);
    if (stopTime == null) return startStr;
    final stopStr = _formatTimeOfDay(stopTime!);
    return '$startStr - $stopStr';
  }

  String _formatTimeOfDay(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
