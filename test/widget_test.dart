import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:speny/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App renders its MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const SpenyApp());
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MaterialApp && widget.title == 'Speny',
      ),
      findsOneWidget,
    );
  });
}
