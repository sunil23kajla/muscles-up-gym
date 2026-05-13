import 'package:flutter_test/flutter_test.dart';
import 'package:gym/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MusclesUpAdminApp());
    expect(find.byType(MusclesUpAdminApp), findsOneWidget);
  });
}
