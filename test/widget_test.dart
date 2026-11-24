import 'package:flutter_test/flutter_test.dart';
import 'package:dailyflow/main.dart';

void main() {
  testWidgets('DailyFlow smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DailyFlowApp());
    expect(find.byType(DailyFlowApp), findsOneWidget);
  });
}
