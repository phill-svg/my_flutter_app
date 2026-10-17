import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_flutter_app/main.dart';
import 'package:my_flutter_app/pokie/pokie_screen.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const PokieApp());
  }

  testWidgets('app opens on the homepage, not the game', (tester) async {
    await pumpHome(tester);
    expect(find.text('LUCKY DIAMONDS'), findsOneWidget);
    expect(find.text('PLAY NOW'), findsOneWidget);
    expect(find.byType(PokieScreen), findsNothing);
  });

  testWidgets('Play now opens the game and back returns home', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('PLAY NOW'));
    await tester.pumpAndSettle();
    expect(find.byType(PokieScreen), findsOneWidget);
    expect(find.text('SPIN'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(PokieScreen), findsNothing);
    expect(find.text('PLAY NOW'), findsOneWidget);
  });

  testWidgets('How to play shows the pay table', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('HOW TO PLAY'));
    await tester.pumpAndSettle();
    expect(find.text('PAY TABLE'), findsOneWidget);
  });
}
