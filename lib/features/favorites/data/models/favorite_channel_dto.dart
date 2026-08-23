import 'package:glitch_tv/features/home/domain/entities/channel_item_entity.dart';
import 'package:glitch_tv/features/home/domain/entities/channels_response_entity.dart';

class FavoriteChannelDto {
  final String id;
  final String name;
  final List<String> altNames;
  final String network;
  final List<String> owners;
  final String country;
  final List<String> categories;
  final bool isNsfw;
  final String launched;
  final String closed;
  final String replacedBy;
  final String website;
  final String logoUrl;

  const FavoriteChannelDto({
    required this.id,
    required this.name,
    required this.altNames,
    required this.network,
    required this.owners,
    required this.country,
    required this.categories,
    required this.isNsfw,
    required this.launched,
    required this.closed,
    required this.replacedBy,
    required this.website,
    required this.logoUrl,
  });

  factory FavoriteChannelDto.fromEntity(ChannelItemEntity entity) {
    return FavoriteChannelDto(
      id: entity.channel.id,
      name: entity.channel.name,
      altNames: List<String>.from(entity.channel.altNames),
      network: entity.channel.network,
      owners: List<String>.from(entity.channel.owners),
      country: entity.channel.country,
      categories: List<String>.from(entity.channel.categories),
      isNsfw: entity.channel.isNsfw,
      launched: entity.channel.launched,
      closed: entity.channel.closed,
      replacedBy: entity.channel.replacedBy,
      website: entity.channel.website,
      logoUrl: entity.logoUrl,
    );
  }

  ChannelItemEntity toEntity() {
    return ChannelItemEntity(
      channel: ChannelsResponseEntity(
        id: id,
        name: name,
        altNames: altNames,
        network: network,
        owners: owners,
        country: country,
        categories: categories,
        isNsfw: isNsfw,
        launched: launched,
        closed: closed,
        replacedBy: replacedBy,
        website: website,
      ),
      logoUrl: logoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'altNames': altNames,
      'network': network,
      'owners': owners,
      'country': country,
      'categories': categories,
      'isNsfw': isNsfw,
      'launched': launched,
      'closed': closed,
      'replacedBy': replacedBy,
      'website': website,
      'logoUrl': logoUrl,
    };
  }

  factory FavoriteChannelDto.fromJson(Map<String, dynamic> json) {
    return FavoriteChannelDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      altNames: (json['altNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      network: json['network'] as String? ?? '',
      owners: (json['owners'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      country: json['country'] as String? ?? '',
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isNsfw: json['isNsfw'] as bool? ?? false,
      launched: json['launched'] as String? ?? '',
      closed: json['closed'] as String? ?? '',
      replacedBy: json['replacedBy'] as String? ?? '',
      website: json['website'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
    );
  }
}
