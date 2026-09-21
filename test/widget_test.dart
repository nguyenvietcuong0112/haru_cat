import 'package:flutter_test/flutter_test.dart';
import 'package:haru_cats/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HaruCatsApp());
    expect(find.byType(HaruCatsApp), findsOneWidget);
  });
}
