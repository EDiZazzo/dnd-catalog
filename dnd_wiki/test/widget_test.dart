import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dnd_wiki/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DnDWikiApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
