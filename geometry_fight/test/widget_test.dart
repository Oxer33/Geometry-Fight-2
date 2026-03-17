import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_fight/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const GeometryFightApp());
    expect(find.text('GEOMETRY\nFIGHT'), findsOneWidget);
  });
}
