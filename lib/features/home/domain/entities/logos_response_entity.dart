class LogosResponseEntity {
  String channel;
  String feed;
  bool inUse;
  List<String> tags;
  int width;
  int height;
  String format;
  String url;

  LogosResponseEntity({
    this.channel = '',
    this.feed = '',
    this.inUse = false,
    this.tags = const [],
    this.width = 0,
    this.height = 0,
    this.format = '',
    this.url = '',
  });
}
