import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:glitch_tv/core/services/api_cache_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('api_cache_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('ApiCacheService put and get within TTL returns cached content', () async {
    final service = ApiCacheService.instance;
    await service.put('test_key', '{"data": "hello"}');

    final result = await service.get('test_key', maxAge: const Duration(hours: 1));
    expect(result, equals('{"data": "hello"}'));
  });

  test('ApiCacheService get returns null when expired', () async {
    final service = ApiCacheService.instance;
    await service.put('expired_key', '{"data": "old"}');

    // maxAge of 0 milliseconds means expired immediately
    final result = await service.get('expired_key', maxAge: const Duration(milliseconds: -1));
    expect(result, isNull);
  });

  test('ApiCacheService getFallback returns expired content for offline resilience', () async {
    final service = ApiCacheService.instance;
    await service.put('fallback_key', '{"data": "resilient"}');

    final fallback = await service.getFallback('fallback_key');
    expect(fallback, equals('{"data": "resilient"}'));
  });

  test('ApiCacheService remove deletes specific key', () async {
    final service = ApiCacheService.instance;
    await service.put('to_delete', 'value');
    await service.remove('to_delete');

    final result = await service.get('to_delete');
    expect(result, isNull);
  });

  test('ApiCacheService clear wipes all entries', () async {
    final service = ApiCacheService.instance;
    await service.put('k1', 'v1');
    await service.put('k2', 'v2');
    await service.clear();

    expect(await service.get('k1'), isNull);
    expect(await service.get('k2'), isNull);
  });
}
