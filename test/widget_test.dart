import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Random Quote Generator smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Pump a frame to let the async initialization complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that our app bar title "InspireMe" is displayed.
    expect(find.text('InspireMe'), findsOneWidget);

    // Verify that the "New Quote" button is present.
    expect(find.text('New Quote'), findsOneWidget);

    // Verify that we display a navigation bar with "Quote" and "Favorites"
    expect(find.text('Quote'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
  });
}
