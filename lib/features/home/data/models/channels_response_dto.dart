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
    if (json['alt_names'] != null && json['alt_names'] is List) {
      altNames = (json['alt_names'] as List).map((v) => v.toString()).toList();
    }
    network = json['network'];
    if (json['owners'] != null && json['owners'] is List) {
      owners = (json['owners'] as List).map((v) => v.toString()).toList();
    }
    country = json['country'];
    if (json['categories'] != null && json['categories'] is List) {
      categories = (json['categories'] as List).map((v) => v.toString()).toList();
    }
    isNsfw = json['is_nsfw'];
    launched = json['launched'];
    closed = json['closed'];
    replacedBy = json['replaced_by'];
    website = json['website'];
  }

  static List<ChannelsResponseDto> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .whereType<Map<String, dynamic>>()
        .map((json) => ChannelsResponseDto.fromJson(json))
        .toList();
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
