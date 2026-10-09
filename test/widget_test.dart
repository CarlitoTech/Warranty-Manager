// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:garantiemanager/main.dart';

void main() {
  testWidgets('App lädt erfolgreich Smoke-Test', (WidgetTester tester) async {
    // Startet deine GarantieApp
    await tester.pumpWidget(const GarantieApp());

    // Überprüft, ob der App-Titel auf dem Bildschirm erscheint
    expect(find.text('Garantie & Bon Sammel-App'), findsOneWidget);
  });
}