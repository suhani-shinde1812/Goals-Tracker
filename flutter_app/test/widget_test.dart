import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bloomtrack/main.dart';

void main() {
  testWidgets('HerBloom app loads and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HerBloomApp()));
    expect(find.text('HerBloom'), findsOneWidget);
  });
}
