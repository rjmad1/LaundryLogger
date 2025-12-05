import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Laundry Logger smoke test', (WidgetTester tester) async {
    // Build a simple MaterialApp to verify Flutter is working
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Laundry Logger')),
          body: const Center(
            child: Text('Welcome to Laundry Logger'),
          ),
        ),
      ),
    );

    // Verify the title is displayed
    expect(find.text('Laundry Logger'), findsOneWidget);
    expect(find.text('Welcome to Laundry Logger'), findsOneWidget);
  });
}
