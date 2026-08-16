import 'dart:convert';
import 'package:glitch_tv/core/utils/app_api.dart';
import 'package:glitch_tv/features/home/data/api/api_result.dart';
import 'package:glitch_tv/features/home/data/models/channels_response_dto.dart';
import 'package:glitch_tv/features/home/data/models/logos_response_dto.dart';
import 'package:http/http.dart' as http;

class HomeApi {
  Future<ApiResult<LogosResponseDto>> fetchLogos() async {
    final url = Uri.https(AppApi.baseUrl, AppApi.logosEndpoint);
    try {
      final response = await http.get(
        url,
      );
      if (response.statusCode != 200) {
        return ApiError('Failed to fetch logos');
      }    
      var responseBody = response.body;
      var json = jsonDecode(responseBody);
      return ApiSuccess(LogosResponseDto.fromJson(json));
    } catch (e) {
      return ApiError(e.toString());
    }
  }

  Future<ApiResult<ChannelsResponseDto>> fetchChannels() async {
    final url = Uri.https(AppApi.baseUrl, AppApi.channelsEndpoint);
    try {
      final response = await http.get(
        url,
      );
      if (response.statusCode != 200) {
        return ApiError('Failed to fetch channels');
      }    
      var responseBody = response.body;
      var json = jsonDecode(responseBody);
      return ApiSuccess(ChannelsResponseDto.fromJson(json));
    } catch (e) {
      return ApiError(e.toString());
    }
  }
}
