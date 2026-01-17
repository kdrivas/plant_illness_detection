// Basic Flutter widget test for Plant Illness Detection app
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_illness_detection/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: PlantIllnessApp()),
    );

    // Verify the app loads without crashing
    await tester.pumpAndSettle();
    
    // The app should be running
    expect(find.byType(PlantIllnessApp), findsOneWidget);
  });
}
