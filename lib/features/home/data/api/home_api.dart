import 'dart:convert';
import 'dart:isolate';
import 'package:glitch_tv/core/utils/api_result.dart';
import 'package:glitch_tv/core/utils/app_api.dart';
import 'package:glitch_tv/features/home/data/models/channels_response_dto.dart';
import 'package:glitch_tv/features/home/data/models/logos_response_dto.dart';
import 'package:http/http.dart' as http;

class HomeApi {
  Future<ApiResult<List<LogosResponseDto>>> fetchLogos() async {
    final url = Uri.https(AppApi.iptvBaseUrl, AppApi.logosEndpoint);
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        return ApiError('Failed to fetch logos (${response.statusCode})');
      }
      final responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
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
      final responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      final dtos = await Isolate.run(() {
        final jsonList = jsonDecode(responseBody) as List<dynamic>;
        return ChannelsResponseDto.fromJsonList(jsonList);
      });
      return ApiSuccess(dtos);
    } catch (e) {
      return ApiError('Channels network error: ${e.toString()}');
    }
  }
}
