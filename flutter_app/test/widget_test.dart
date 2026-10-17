import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bloomtrack/main.dart';

void main() {
  testWidgets('BloomTrack app loads and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BloomTrackApp()));
    expect(find.text('BloomTrack'), findsOneWidget);
  });
}
