import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'colors.dart';
import 'slot_engine.dart';

const int startingCredits = 1000;
const List<int> lineBetOptions = [1, 2, 5, 10, 20];

String formatCredits(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class PokieScreen extends StatefulWidget {
  const PokieScreen({super.key, this.engine});

  /// Injected in tests to make spins deterministic.
  final SlotEngine? engine;

  @override
  State<PokieScreen> createState() => _PokieScreenState();
}

class _PokieScreenState extends State<PokieScreen>
    with TickerProviderStateMixin {
  late final SlotEngine _engine = widget.engine ?? SlotEngine();
  late final List<AnimationController> _controllers;
  late List<Animation<double>> _positions;

  int _credits = startingCredits;
  int _betIndex = 0;
  bool _spinning = false;
  bool _autoSpin = false;
  SpinResult? _result;

  int get _lineBet => lineBetOptions[_betIndex];
  int get _totalBet => _lineBet * _engine.lineCount;
  bool get _canSpin => !_spinning && _credits >= _totalBet;

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (var i = 0; i < reelCount; i++) AnimationController(vsync: this),
    ];
    _positions = [
      for (final strip in _engine.reels)
        AlwaysStoppedAnimation(Random().nextInt(strip.length).toDouble()),
    ];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _spin() async {
    if (!_canSpin) return;
    final result = _engine.spin(_lineBet);
    setState(() {
      _credits -= _totalBet;
      _spinning = true;
      _result = null;
    });

    final spins = <Future<void>>[];
    for (var i = 0; i < reelCount; i++) {
      final length = _engine.reels[i].length;
      final start = _positions[i].value.round() % length;
      final offset = (result.stops[i] - start) % length;
      final controller = _controllers[i]
        ..duration = Duration(milliseconds: 900 + i * 250);
      _positions[i] = Tween<double>(
        begin: start.toDouble(),
        end: (start + (3 + i) * length + offset).toDouble(),
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
      spins.add(controller.forward(from: 0));
    }
    await Future.wait(spins);
    if (!mounted) return;

    setState(() {
      _positions = [
        for (final stop in result.stops)
          AlwaysStoppedAnimation(stop.toDouble()),
      ];
      _credits += result.totalWin;
      _result = result;
      _spinning = false;
      if (_credits < _totalBet) _autoSpin = false;
    });

    if (_autoSpin) {
      await Future<void>.delayed(
        Duration(milliseconds: result.totalWin > 0 ? 1400 : 500),
      );
      if (mounted && _autoSpin) unawaited(_spin());
    }
  }

  void _toggleAuto() {
    setState(() => _autoSpin = !_autoSpin);
    if (_autoSpin) _spin();
  }

  void _changeBet(int delta) {
    setState(() {
      _betIndex = (_betIndex + delta).clamp(0, lineBetOptions.length - 1);
    });
  }

  void _topUp() => setState(() => _credits += startingCredits);

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final win = result?.totalWin ?? 0;

    return Scaffold(
      backgroundColor: pokieFelt,
      appBar: AppBar(
        backgroundColor: pokieFelt,
        foregroundColor: pokieGold,
        centerTitle: true,
        title: const Text(
          'LUCKY DIAMONDS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        actions: [
          IconButton(
            tooltip: 'Pay table',
            icon: const Icon(Icons.info_outline),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: pokiePanel,
              isScrollControlled: true,
              builder: (_) => PayTable(lineBet: _lineBet),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ReelWindow(
                  reels: _engine.reels,
                  positions: _positions,
                  winningCells: _spinning
                      ? const {}
                      : result?.winningCells ?? const {},
                ),
                const SizedBox(height: 16),
                _WinBanner(result: _spinning ? null : result),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Meter(
                        label: 'CREDITS',
                        value: formatCredits(_credits),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Meter(
                        label: 'BET',
                        value: formatCredits(_totalBet),
                        caption: '$_lineBet × ${_engine.lineCount} lines',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Meter(
                        label: 'WIN',
                        value: _spinning ? '—' : formatCredits(win),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _Controls(
                  canSpin: _canSpin,
                  spinning: _spinning,
                  autoSpin: _autoSpin,
                  canLowerBet: !_spinning && _betIndex > 0,
                  canRaiseBet:
                      !_spinning && _betIndex < lineBetOptions.length - 1,
                  onSpin: _spin,
                  onToggleAuto: _toggleAuto,
                  onBetDown: () => _changeBet(-1),
                  onBetUp: () => _changeBet(1),
                ),
                if (!_spinning && _credits < _totalBet) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pokieGold,
                      ),
                      onPressed: _topUp,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        'Out of credits: top up '
                        '${formatCredits(startingCredits)} free',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Free play only. Credits have no cash value and cannot be '
                  'bought or cashed out.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReelWindow extends StatelessWidget {
  const _ReelWindow({
    required this.reels,
    required this.positions,
    required this.winningCells,
  });

  final List<List<Sym>> reels;
  final List<Animation<double>> positions;
  final Set<(int, int)> winningCells;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE08A), Color(0xFFB8860B), Color(0xFFFFE08A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: pokieGold.withValues(alpha: 0.35), blurRadius: 24),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: reelCount / rowCount,
          child: Container(
            color: const Color(0xFF12061F),
            child: Row(
              children: [
                for (var reel = 0; reel < reelCount; reel++)
                  Expanded(
                    child: _Reel(
                      strip: reels[reel],
                      position: positions[reel],
                      highlightedRows: {
                        for (final (row, r) in winningCells)
                          if (r == reel) row,
                      },
                      dimOthers: winningCells.isNotEmpty,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Reel extends StatelessWidget {
  const _Reel({
    required this.strip,
    required this.position,
    required this.highlightedRows,
    required this.dimOthers,
  });

  final List<Sym> strip;
  final Animation<double> position;
  final Set<int> highlightedRows;
  final bool dimOthers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellHeight = constraints.maxHeight / rowCount;
        return Container(
          decoration: const BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(color: Color(0x33FFFFFF), width: 0.5),
            ),
          ),
          child: ClipRect(
            child: AnimatedBuilder(
              animation: position,
              builder: (context, _) {
                final p = position.value;
                final base = p.floor();
                final frac = p - base;
                final settled = frac == 0;
                return Stack(
                  children: [
                    for (var k = 0; k <= rowCount; k++)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: (k - frac) * cellHeight,
                        height: cellHeight,
                        child: _Cell(
                          symbol: strip[(base + k) % strip.length],
                          highlighted: settled && highlightedRows.contains(k),
                          dimmed:
                              settled &&
                              dimOthers &&
                              !highlightedRows.contains(k),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.symbol,
    required this.highlighted,
    required this.dimmed,
  });

  final Sym symbol;
  final bool highlighted;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dimmed ? 0.35 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: highlighted ? pokieGold.withValues(alpha: 0.18) : null,
          border: Border.all(
            color: highlighted ? pokieGold : Colors.transparent,
            width: 2,
          ),
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              symbol.glyph,
              semanticsLabel: symbol.label,
              style: const TextStyle(fontSize: 40),
            ),
          ),
        ),
      ),
    );
  }
}

class _WinBanner extends StatelessWidget {
  const _WinBanner({required this.result});

  final SpinResult? result;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    final win = result?.totalWin ?? 0;
    final String headline;
    final String detail;
    if (result == null) {
      headline = 'GOOD LUCK!';
      detail = '';
    } else if (win == 0) {
      headline = 'NO WIN';
      detail = 'Spin again';
    } else {
      headline = 'WIN ${formatCredits(win)}';
      detail = [
        for (final w in result.lineWins)
          'Line ${w.line + 1}: ${w.count} × ${w.symbol.glyph}',
        if (result.scatterWin > 0)
          '${result.scatterCount} × ${Sym.scatter.glyph} scatter',
      ].join('   ');
    }

    return SizedBox(
      height: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: win > 0 ? pokieGold : Colors.white70,
              fontSize: win > 0 ? 30 : 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
            child: Text(headline),
          ),
          if (detail.isNotEmpty)
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value, this.caption});

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: pokiePanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pokieGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: pokieGold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (caption != null)
            Text(
              caption!,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.canSpin,
    required this.spinning,
    required this.autoSpin,
    required this.canLowerBet,
    required this.canRaiseBet,
    required this.onSpin,
    required this.onToggleAuto,
    required this.onBetDown,
    required this.onBetUp,
  });

  final bool canSpin;
  final bool spinning;
  final bool autoSpin;
  final bool canLowerBet;
  final bool canRaiseBet;
  final VoidCallback onSpin;
  final VoidCallback onToggleAuto;
  final VoidCallback onBetDown;
  final VoidCallback onBetUp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundButton(
          tooltip: 'Lower bet',
          icon: Icons.remove,
          onPressed: canLowerBet ? onBetDown : null,
        ),
        _RoundButton(
          tooltip: autoSpin ? 'Stop auto spin' : 'Auto spin',
          icon: autoSpin ? Icons.stop : Icons.autorenew,
          active: autoSpin,
          onPressed: autoSpin || canSpin ? onToggleAuto : null,
        ),
        SizedBox(
          width: 104,
          height: 104,
          child: FilledButton(
            onPressed: canSpin && !autoSpin ? onSpin : null,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xFFE53950),
              disabledBackgroundColor: const Color(0xFF5A2A3A),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFFE53950),
            ),
            child: Text(
              spinning ? '...' : 'SPIN',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        _RoundButton(
          tooltip: 'Raise bet',
          icon: Icons.add,
          onPressed: canRaiseBet ? onBetUp : null,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      iconSize: 28,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: active ? pokieGold : pokiePanel,
        foregroundColor: active ? pokieFelt : pokieGold,
        disabledBackgroundColor: pokiePanel.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white24,
        side: BorderSide(color: pokieGold.withValues(alpha: 0.5)),
        padding: const EdgeInsets.all(14),
      ),
      icon: Icon(icon),
    );
  }
}

class PayTable extends StatelessWidget {
  const PayTable({super.key, required this.lineBet});

  final int lineBet;

  @override
  Widget build(BuildContext context) {
    const heading = TextStyle(
      color: pokieGold,
      fontWeight: FontWeight.w800,
      fontSize: 16,
      letterSpacing: 1.5,
    );
    const body = TextStyle(color: Colors.white70);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const Text('PAY TABLE', style: heading),
          Text('Wins shown for a line bet of $lineBet.', style: body),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {0: FlexColumnWidth(2)},
            children: [
              const TableRow(
                children: [
                  SizedBox(),
                  Text('×3', style: heading, textAlign: TextAlign.end),
                  Text('×4', style: heading, textAlign: TextAlign.end),
                  Text('×5', style: heading, textAlign: TextAlign.end),
                ],
              ),
              for (final entry in linePays.entries.toList().reversed)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${entry.key.glyph}  ${entry.key.label}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    for (final pay in entry.value)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          formatCredits(pay * lineBet),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${Sym.wild.glyph} Wild substitutes for every symbol except '
            '${Sym.scatter.glyph}.',
            style: body,
          ),
          const SizedBox(height: 6),
          Text(
            '${Sym.scatter.glyph} Scatter pays anywhere on the reels: '
            '3 = ${scatterPays[0]}×, 4 = ${scatterPays[1]}×, '
            '5 = ${scatterPays[2]}× total bet.',
            style: body,
          ),
          const SizedBox(height: 6),
          const Text(
            'Line wins pay left to right from the first reel. Only the '
            'highest win on each line is paid.',
            style: body,
          ),
          const SizedBox(height: 20),
          Text('${paylines.length} PAYLINES', style: heading),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < paylines.length; i++)
                _PaylineDiagram(index: i),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaylineDiagram extends StatelessWidget {
  const _PaylineDiagram({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final line = paylines[index];
    return Column(
      children: [
        for (var row = 0; row < rowCount; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var reel = 0; reel < reelCount; reel++)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.all(1),
                  color: line[reel] == row ? pokieGold : Colors.white12,
                ),
            ],
          ),
        const SizedBox(height: 2),
        Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
