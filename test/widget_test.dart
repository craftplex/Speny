import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speny/main.dart';

void main() {
  testWidgets('App renders Speny title smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SpenyApp());
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Speny Tracker'), findsOneWidget);
  });
}
