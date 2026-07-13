import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hastane_uygulama/main.dart';

void main() {
  testWidgets('App loads bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(HastaneApp());

    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Yemekler'), findsOneWidget);
    expect(find.text('İletişim'), findsOneWidget);
    expect(find.text('Öneri'), findsOneWidget);
  });
}
