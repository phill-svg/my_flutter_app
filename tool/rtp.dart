// ignore_for_file: avoid_print

// Estimates the return-to-player of the default reels by simulation.
// Run with: dart run tool/rtp.dart [spins]
import 'dart:math';

import 'package:my_flutter_app/pokie/slot_engine.dart';

void main(List<String> args) {
  final spins = args.isEmpty ? 1000000 : int.parse(args.first);
  final engine = SlotEngine(random: Random(1));
  var won = 0;
  var hits = 0;
  var scatterWon = 0;
  for (var i = 0; i < spins; i++) {
    final result = engine.spin(1);
    won += result.totalWin;
    scatterWon += result.scatterWin;
    if (result.totalWin > 0) hits++;
  }
  final bet = spins * engine.lineCount;
  print('Spins:        $spins');
  print('RTP:          ${(100 * won / bet).toStringAsFixed(2)}%');
  print('  scatter:    ${(100 * scatterWon / bet).toStringAsFixed(2)}%');
  print('Hit rate:     ${(100 * hits / spins).toStringAsFixed(2)}%');
}
