import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:glitch_tv/core/utils/app_router.dart';
import 'package:glitch_tv/main.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    AppRouter.initializeRouter();
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
