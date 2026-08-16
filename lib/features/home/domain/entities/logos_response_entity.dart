class LogosResponseEntity {
  String channel;
  bool inUse;
  int width;
  int height;
  String format;
  String url;

  LogosResponseEntity({
    this.channel = '',
    this.inUse = false,
    this.width = 0,
    this.height = 0,
    this.format = '',
    this.url = '',
  });
}
