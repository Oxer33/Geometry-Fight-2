import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_fight/main.dart';

void main() {
  // Ensure the test binding is initialized before any pumpWidget call.
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GeometryFightApp());
    // Splash screen has an indefinite animation that never settles; use a
    // bounded pump instead of pumpAndSettle to avoid timeout.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GeometryFightApp), findsOneWidget);
  });
}
