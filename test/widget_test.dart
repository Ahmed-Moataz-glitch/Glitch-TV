// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:glitch_tv/core/utils/app_router.dart';

import 'package:glitch_tv/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    AppRouter.initializeRouter();
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
