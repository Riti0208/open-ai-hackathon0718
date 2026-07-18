import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seal_app/main.dart';

void main() {
  testWidgets('音声会話を始めるボタンが表示される', (tester) async {
    await tester.pumpWidget(const SealApp());

    expect(find.byKey(const Key('mouth-icon')), findsOneWidget);
    expect(find.text('作る'), findsOneWidget);
    expect(find.text('コレクション'), findsOneWidget);
  });
}
