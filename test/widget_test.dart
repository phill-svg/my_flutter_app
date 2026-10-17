import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_flutter_app/main.dart';
import 'package:my_flutter_app/pokie/pokie_screen.dart';
import 'package:my_flutter_app/pokie/slot_engine.dart';

void main() {
  Future<void> pumpPokie(WidgetTester tester, {int seed = 3}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PokieApp(
        home: PokieScreen(engine: SlotEngine(random: Random(seed))),
      ),
    );
  }

  test('formatCredits adds thousands separators', () {
    expect(formatCredits(0), '0');
    expect(formatCredits(999), '999');
    expect(formatCredits(1000), '1,000');
    expect(formatCredits(1234567), '1,234,567');
  });

  testWidgets('spinning takes the bet and pays the win', (tester) async {
    await pumpPokie(tester);
    expect(find.text('1,000'), findsOneWidget);
    expect(find.text('GOOD LUCK!'), findsOneWidget);

    await tester.tap(find.text('SPIN'));
    await tester.pump();
    expect(find.text('990'), findsOneWidget);

    await tester.pumpAndSettle();
    final win = SlotEngine(random: Random(3)).spin(1).totalWin;
    expect(find.text(formatCredits(1000 - 10 + win)), findsOneWidget);
    expect(
      find.text(win > 0 ? 'WIN ${formatCredits(win)}' : 'NO WIN'),
      findsOneWidget,
    );
  });

  testWidgets('bet buttons step through the line bets', (tester) async {
    await pumpPokie(tester);
    expect(find.text('1 × 10 lines'), findsOneWidget);

    await tester.tap(find.byTooltip('Raise bet'));
    await tester.pump();
    expect(find.text('2 × 10 lines'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);

    await tester.tap(find.byTooltip('Lower bet'));
    await tester.pump();
    expect(find.text('1 × 10 lines'), findsOneWidget);
  });

  testWidgets('pay table opens', (tester) async {
    await pumpPokie(tester);
    await tester.tap(find.byTooltip('Pay table'));
    await tester.pumpAndSettle();
    expect(find.text('PAY TABLE'), findsOneWidget);
    expect(find.text('10 PAYLINES'), findsOneWidget);
  });
}
