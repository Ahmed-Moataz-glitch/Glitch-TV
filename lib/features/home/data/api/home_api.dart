import 'dart:convert';
import 'dart:isolate';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/core/utils/app_api.dart';
import 'package:glitch_tv/features/home/data/models/channels_response_dto.dart';
import 'package:glitch_tv/features/home/data/models/logos_response_dto.dart';
import 'package:glitch_tv/features/home/data/models/podcast_dto.dart';
import 'package:glitch_tv/features/home/data/models/radio_station_dto.dart';
import 'package:http/http.dart' as http;

class HomeApi {
  Future<ApiResult<List<LogosResponseDto>>> fetchLogos() async {
    final url = Uri.https(AppApi.iptvBaseUrl, AppApi.logosEndpoint);
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        return ApiError('Failed to fetch logos (${response.statusCode})');
      }
      final responseBody = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );
      final dtos = await Isolate.run(() {
        final jsonList = jsonDecode(responseBody) as List<dynamic>;
        return LogosResponseDto.fromJsonList(jsonList);
      });
      return ApiSuccess(dtos);
    } catch (e) {
      return ApiError('Logos network error: ${e.toString()}');
    }
  }

  Future<ApiResult<List<ChannelsResponseDto>>> fetchChannels() async {
    final url = Uri.https(AppApi.iptvBaseUrl, AppApi.channelsEndpoint);
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        return ApiError('Failed to fetch channels (${response.statusCode})');
      }
      final responseBody = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );
      final dtos = await Isolate.run(() {
        final jsonList = jsonDecode(responseBody) as List<dynamic>;
        return ChannelsResponseDto.fromJsonList(jsonList);
      });
      return ApiSuccess(dtos);
    } catch (e) {
      return ApiError('Channels network error: ${e.toString()}');
    }
  }

  Future<ApiResult<List<RadioStationDto>>> fetchRadioStations() async {
    final url = Uri.https(AppApi.radioBaseUrl, AppApi.radioStationsEndpoint);
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return ApiError('Failed to fetch radio stations (${response.statusCode})');
      }
      final responseBody = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );
      final dtos = await Isolate.run(() {
        final decoded = jsonDecode(responseBody);
        final List<dynamic> jsonList;
        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          jsonList = decoded['results'] as List<dynamic>? ?? [];
        } else {
          jsonList = [];
        }
        return RadioStationDto.fromJsonList(jsonList);
      });
      return ApiSuccess(dtos);
    } catch (e) {
      return ApiError('Radio stations network error: ${e.toString()}');
    }
  }

  Future<ApiResult<List<PodcastDto>>> fetchPodcasts() async {
    final url = Uri.https(AppApi.podcastsBaseUrl, AppApi.podcastsEndpoint, {
      'id': AppApi.podcastsIds,
    });
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return ApiError('Failed to fetch podcasts (${response.statusCode})');
      }
      final responseBody = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );
      final dtos = await Isolate.run(() {
        final decoded = jsonDecode(responseBody);
        final List<dynamic> jsonList;
        if (decoded is Map<String, dynamic>) {
          jsonList = decoded['results'] as List<dynamic>? ?? [];
        } else if (decoded is List) {
          jsonList = decoded;
        } else {
          jsonList = [];
        }
        return PodcastDto.fromJsonList(jsonList);
      });
      return ApiSuccess(dtos);
    } catch (e) {
      return ApiError('Podcasts network error: ${e.toString()}');
    }
  }
}
