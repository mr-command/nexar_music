import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexar_app/main.dart';

void main() {
  testWidgets('Nexar app renders its shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NexarApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
