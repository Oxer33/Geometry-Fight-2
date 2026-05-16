import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_fight/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const GeometryFightApp());
    await tester.pumpAndSettle();
    expect(find.text('SKIP'), findsOneWidget);
  });
}
