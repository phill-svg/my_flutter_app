import 'package:flutter/material.dart';

import 'colors.dart';
import 'pokie_screen.dart';
import 'slot_engine.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _play(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PokieScreen()));
  }

  void _howToPlay(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: pokiePanel,
      isScrollControlled: true,
      builder: (_) => const PayTable(lineBet: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.2,
            colors: [Color(0xFF4A1F7A), pokieFelt],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                children: [
                  const _Logo(),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 64,
                    child: FilledButton(
                      onPressed: () => _play(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE53950),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0xFFE53950),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: const Text(
                        'PLAY NOW',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _howToPlay(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pokieGold,
                        side: const BorderSide(color: pokieGold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text(
                        'HOW TO PLAY',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      Expanded(
                        child: _Feature(
                          glyph: '🪙',
                          title: formatCredits(startingCredits),
                          caption: 'free credits',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Feature(
                          glyph: '🎰',
                          title: '${paylines.length}',
                          caption: 'paylines',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Feature(
                          glyph: Sym.wild.glyph,
                          title: 'Wilds',
                          caption: '& scatters',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
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
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pokiePanel,
            border: Border.all(color: pokieGold, width: 3),
            boxShadow: [
              BoxShadow(
                color: pokieGold.withValues(alpha: 0.45),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Text(Sym.wild.glyph, style: const TextStyle(fontSize: 72)),
        ),
        const SizedBox(height: 28),
        const FittedBox(
          child: Text(
            'LUCKY DIAMONDS',
            style: TextStyle(
              color: pokieGold,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Spin the reels for free',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 20),
        Text(
          [
            Sym.cherry,
            Sym.bell,
            Sym.seven,
            Sym.clover,
            Sym.scatter,
          ].map((s) => s.glyph).join('  '),
          style: const TextStyle(fontSize: 28),
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.glyph,
    required this.title,
    required this.caption,
  });

  final String glyph;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: pokiePanel.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pokieGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(glyph, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            caption,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
