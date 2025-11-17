import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare_id/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows welcome and tiles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Halo'), findsOneWidget);
    expect(find.textContaining('Kenali'), findsOneWidget);
    expect(find.text('Cek Penyakit'), findsOneWidget);
  });
}
