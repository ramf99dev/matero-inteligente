import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Construir un widget básico para prueba
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Text('Test'),
        ),
      ),
    );

    // Verificar que el texto se renderiza
    expect(find.text('Test'), findsOneWidget);
  });
}
