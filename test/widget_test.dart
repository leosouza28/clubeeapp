import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_clubee/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ClubeeApp());

    // Verify that the bottom navigation bar is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that all navigation items are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Sobre'), findsOneWidget);
    expect(find.text('Notícias'), findsOneWidget);
    expect(find.text('Conta'), findsOneWidget);
  });
}
