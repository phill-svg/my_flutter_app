import 'dart:math';

/// Every symbol that can land on a reel.
enum Sym {
  cherry('🍒', 'Cherry'),
  lemon('🍋', 'Lemon'),
  orange('🍊', 'Orange'),
  grape('🍇', 'Grapes'),
  bell('🔔', 'Bell'),
  clover('🍀', 'Clover'),
  seven('7️⃣', 'Seven'),
  wild('💎', 'Wild'),
  scatter('⭐', 'Scatter');

  const Sym(this.glyph, this.label);

  final String glyph;
  final String label;
}

const int reelCount = 5;
const int rowCount = 3;

/// Payline shapes: the row index (0 = top) used on each reel.
const List<List<int>> paylines = [
  [1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0],
  [2, 2, 2, 2, 2],
  [0, 1, 2, 1, 0],
  [2, 1, 0, 1, 2],
  [0, 0, 1, 2, 2],
  [2, 2, 1, 0, 0],
  [1, 0, 0, 0, 1],
  [1, 2, 2, 2, 1],
  [1, 0, 1, 2, 1],
];

/// Line pays as multiples of the line bet, for 3, 4 and 5 of a kind.
const Map<Sym, List<int>> linePays = {
  Sym.cherry: [8, 25, 75],
  Sym.lemon: [8, 25, 75],
  Sym.orange: [10, 30, 100],
  Sym.grape: [10, 30, 100],
  Sym.bell: [20, 60, 200],
  Sym.clover: [25, 100, 300],
  Sym.seven: [50, 250, 1000],
  Sym.wild: [100, 500, 2500],
};

/// Scatter pays as multiples of the total bet, for 3, 4 and 5 anywhere.
const List<int> scatterPays = [3, 15, 75];

List<Sym> _strip(Map<Sym, int> counts, int seed) {
  // A fixed shuffle keeps each reel's layout stable between runs.
  return [
    for (final MapEntry(key: sym, value: n) in counts.entries)
      for (var i = 0; i < n; i++) sym,
  ]..shuffle(Random(seed));
}

/// Default reel strips. Low symbols are common, wilds and sevens are rare.
final List<List<Sym>> defaultReels = [
  for (var i = 0; i < reelCount; i++)
    _strip({
      Sym.cherry: 7,
      Sym.lemon: 7,
      Sym.orange: 6,
      Sym.grape: 6,
      Sym.bell: 4,
      Sym.clover: 3,
      Sym.seven: 2,
      Sym.wild: i == 0 ? 1 : 2,
      Sym.scatter: 2,
    }, i + 1),
];

class LineWin {
  const LineWin({
    required this.line,
    required this.symbol,
    required this.count,
    required this.amount,
  });

  /// Zero-based payline index.
  final int line;
  final Sym symbol;
  final int count;
  final int amount;

  /// Cells (row, reel) that make up this win.
  List<(int, int)> get cells => [
    for (var reel = 0; reel < count; reel++) (paylines[line][reel], reel),
  ];
}

class SpinResult {
  const SpinResult({
    required this.stops,
    required this.grid,
    required this.lineWins,
    required this.scatterCount,
    required this.scatterWin,
  });

  /// Strip index shown in the top row of each reel.
  final List<int> stops;

  /// grid[row][reel].
  final List<List<Sym>> grid;
  final List<LineWin> lineWins;
  final int scatterCount;
  final int scatterWin;

  int get totalWin => lineWins.fold(0, (sum, w) => sum + w.amount) + scatterWin;

  Set<(int, int)> get winningCells => {
    for (final w in lineWins) ...w.cells,
    if (scatterWin > 0)
      for (var row = 0; row < rowCount; row++)
        for (var reel = 0; reel < reelCount; reel++)
          if (grid[row][reel] == Sym.scatter) (row, reel),
  };
}

class SlotEngine {
  SlotEngine({Random? random, List<List<Sym>>? reels})
    : _random = random ?? Random.secure(),
      reels = reels ?? defaultReels;

  final Random _random;
  final List<List<Sym>> reels;

  int get lineCount => paylines.length;

  SpinResult spin(int lineBet) {
    final stops = [for (final strip in reels) _random.nextInt(strip.length)];
    return evaluate(stops, lineBet);
  }

  SpinResult evaluate(List<int> stops, int lineBet) {
    final grid = [
      for (var row = 0; row < rowCount; row++)
        [
          for (var reel = 0; reel < reelCount; reel++)
            reels[reel][(stops[reel] + row) % reels[reel].length],
        ],
    ];

    final lineWins = <LineWin>[];
    for (var line = 0; line < paylines.length; line++) {
      final symbols = [
        for (var reel = 0; reel < reelCount; reel++)
          grid[paylines[line][reel]][reel],
      ];
      final win = _evaluateLine(symbols, lineBet);
      if (win != null) {
        lineWins.add(
          LineWin(line: line, symbol: win.$1, count: win.$2, amount: win.$3),
        );
      }
    }

    final scatterCount = grid
        .expand((r) => r)
        .where((s) => s == Sym.scatter)
        .length;
    final scatterWin = scatterCount >= 3
        ? scatterPays[min(scatterCount, 5) - 3] * lineBet * lineCount
        : 0;

    return SpinResult(
      stops: stops,
      grid: grid,
      lineWins: lineWins,
      scatterCount: scatterCount,
      scatterWin: scatterWin,
    );
  }

  /// Best left-to-right win on one line, as (symbol, count, amount).
  (Sym, int, int)? _evaluateLine(List<Sym> symbols, int lineBet) {
    if (symbols.first == Sym.scatter) return null;

    // A run of wilds can pay as wilds on its own.
    var wildRun = 0;
    while (wildRun < symbols.length && symbols[wildRun] == Sym.wild) {
      wildRun++;
    }

    // Wilds also substitute for the first regular symbol on the line.
    final target = symbols.firstWhere(
      (s) => s != Sym.wild,
      orElse: () => Sym.wild,
    );
    var run = 0;
    if (target != Sym.scatter) {
      while (run < symbols.length &&
          (symbols[run] == target || symbols[run] == Sym.wild)) {
        run++;
      }
    }

    int pay(Sym sym, int count) =>
        count >= 3 ? linePays[sym]![count - 3] * lineBet : 0;

    final wildPay = pay(Sym.wild, wildRun);
    final targetPay = target == Sym.scatter ? 0 : pay(target, run);
    if (wildPay == 0 && targetPay == 0) return null;
    return wildPay >= targetPay
        ? (Sym.wild, wildRun, wildPay)
        : (target, run, targetPay);
  }
}
