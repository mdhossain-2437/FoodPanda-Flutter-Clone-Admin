import 'package:flutter_test/flutter_test.dart';
import 'package:foodpanda_admin/main.dart';

void main() {
  testWidgets('FoodPanda Admin smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
