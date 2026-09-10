import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrabalhaki/main.dart';

void main() {
  testWidgets('TrabalhakiApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TrabalhakiApp());
    expect(find.text('Trabalhaki'), findsOneWidget);
    // Pump past splash screen timer
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
