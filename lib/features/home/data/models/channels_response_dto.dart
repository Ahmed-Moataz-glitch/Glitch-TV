import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';

class ChannelsResponseDto {
  String? id;
  String? name;
  List<String>? altNames;
  String? network;
  List<String>? owners;
  String? country;
  List<String>? categories;
  bool? isNsfw;
  String? launched;
  String? closed;
  String? replacedBy;
  String? website;

  ChannelsResponseDto(
      {this.id,
      this.name,
      this.altNames,
      this.network,
      this.owners,
      this.country,
      this.categories,
      this.isNsfw,
      this.launched,
      this.closed,
      this.replacedBy,
      this.website});

  ChannelsResponseDto.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['alt_names'] != String) {
      altNames = <String>[];
      json['alt_names'].forEach((v) {
        altNames!.add(v);
      });
    }
    network = json['network'];
    if (json['owners'] != String) {
      owners = <String>[];
      json['owners'].forEach((v) {
        owners!.add(v);
      });
    }
    country = json['country'];
    categories = json['categories'].cast<String>();
    isNsfw = json['is_nsfw'];
    launched = json['launched'];
    closed = json['closed'];
    replacedBy = json['replaced_by'];
    website = json['website'];
  }

  ChannelsResponseEntity toEntity() {
    return ChannelsResponseEntity(
      id: id ?? '',
      name: name ?? '',
      altNames: altNames ?? [],
      network: network ?? '',
      owners: owners ?? [],
      country: country ?? '',
      categories: categories ?? [],
      isNsfw: isNsfw ?? false,
      launched: launched ?? '',
      closed: closed ?? '',
      replacedBy: replacedBy ?? '',
      website: website ?? '',
    );
  }
}
