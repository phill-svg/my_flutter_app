import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/pokie/slot_engine.dart';

/// Evaluates a fixed 3×5 grid given as rows.
SpinResult evaluateGrid(List<List<Sym>> rows, {int lineBet = 1}) {
  final reels = [
    for (var reel = 0; reel < reelCount; reel++)
      [for (final row in rows) row[reel]],
  ];
  return SlotEngine(reels: reels).evaluate(List.filled(reelCount, 0), lineBet);
}

LineWin middleLine(SpinResult result) =>
    result.lineWins.singleWhere((w) => w.line == 0);

void main() {
  const top = [Sym.lemon, Sym.orange, Sym.grape, Sym.bell, Sym.clover];
  const bottom = [Sym.grape, Sym.bell, Sym.clover, Sym.orange, Sym.lemon];

  test('three of a kind on a payline pays line bet × multiplier', () {
    final result = evaluateGrid([
      top,
      [Sym.cherry, Sym.cherry, Sym.cherry, Sym.lemon, Sym.orange],
      bottom,
    ], lineBet: 2);

    expect(result.lineWins, hasLength(1));
    final win = middleLine(result);
    expect(win.symbol, Sym.cherry);
    expect(win.count, 3);
    expect(win.amount, linePays[Sym.cherry]![0] * 2);
    expect(result.totalWin, win.amount);
    expect(result.winningCells, {(1, 0), (1, 1), (1, 2)});
  });

  test('wild substitutes for the first regular symbol', () {
    final win = middleLine(
      evaluateGrid([
        top,
        [Sym.wild, Sym.seven, Sym.seven, Sym.seven, Sym.lemon],
        bottom,
      ]),
    );
    expect(win.symbol, Sym.seven);
    expect(win.count, 4);
    expect(win.amount, linePays[Sym.seven]![1]);
  });

  test('a run of wilds pays as wilds when that is worth more', () {
    final win = middleLine(
      evaluateGrid([
        top,
        [Sym.wild, Sym.wild, Sym.wild, Sym.cherry, Sym.cherry],
        bottom,
      ]),
    );
    expect(win.symbol, Sym.wild);
    expect(win.count, 3);
    expect(win.amount, linePays[Sym.wild]![0]);
  });

  test('five wilds pay the top prize', () {
    final win = middleLine(
      evaluateGrid([top, List.filled(reelCount, Sym.wild), bottom]),
    );
    expect(win.amount, linePays[Sym.wild]![2]);
  });

  test('wins must start on the first reel', () {
    final result = evaluateGrid([
      top,
      [Sym.lemon, Sym.seven, Sym.seven, Sym.seven, Sym.seven],
      bottom,
    ]);
    expect(result.lineWins.where((w) => w.line == 0), isEmpty);
  });

  test('scatters pay anywhere as a multiple of the total bet', () {
    final result = evaluateGrid([
      [Sym.scatter, Sym.orange, Sym.grape, Sym.bell, Sym.clover],
      [Sym.lemon, Sym.cherry, Sym.scatter, Sym.lemon, Sym.orange],
      [Sym.grape, Sym.bell, Sym.clover, Sym.orange, Sym.scatter],
    ], lineBet: 5);
    expect(result.scatterCount, 3);
    expect(result.scatterWin, scatterPays[0] * 5 * paylines.length);
    expect(result.lineWins, isEmpty);
    expect(result.winningCells, {(0, 0), (1, 2), (2, 4)});
  });

  test('spin lands on the strip symbols at its stops', () {
    final engine = SlotEngine(random: Random(3));
    for (var i = 0; i < 100; i++) {
      final result = engine.spin(1);
      for (var reel = 0; reel < reelCount; reel++) {
        final strip = engine.reels[reel];
        expect(result.stops[reel], inInclusiveRange(0, strip.length - 1));
        for (var row = 0; row < rowCount; row++) {
          expect(
            result.grid[row][reel],
            strip[(result.stops[reel] + row) % strip.length],
          );
        }
      }
    }
  });

  test('return to player is in a realistic range', () {
    final engine = SlotEngine(random: Random(7));
    const spins = 300000;
    var won = 0;
    for (var i = 0; i < spins; i++) {
      won += engine.spin(1).totalWin;
    }
    final rtp = won / (spins * engine.lineCount);
    expect(rtp, inInclusiveRange(0.88, 0.98));
  });
}
