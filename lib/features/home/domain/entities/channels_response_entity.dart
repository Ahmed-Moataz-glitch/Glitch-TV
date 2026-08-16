class ChannelsResponseEntity {
  String id;
  String name;
  List<String> altNames;
  String network;
  List<String> owners;
  String country;
  List<String> categories;
  bool isNsfw;
  String launched;
  String closed;
  String replacedBy;
  String website;

  ChannelsResponseEntity({
    this.id = '',
    this.name = '',
    this.altNames = const [],
    this.network = '',
    this.owners = const [],
    this.country = '',
    this.categories = const [],
    this.isNsfw = false,
    this.launched = '',
    this.closed = '',
    this.replacedBy = '',
    this.website = '',
  });
}
