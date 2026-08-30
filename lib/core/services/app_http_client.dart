import 'package:http/http.dart' as http;

class AppHttpClient {
  static http.Client? _client;

  static http.Client get client {
    _client ??= http.Client();
    return _client!;
  }

  static const Map<String, String> defaultHeaders = {
    'Accept-Encoding': 'gzip, deflate, br',
    'User-Agent': 'GlitchTV/1.0 (Linux; Android 14; Mobile)',
    'Accept': 'application/json, text/plain, */*',
  };

  static void reset() {
    _client?.close();
    _client = null;
  }
}
