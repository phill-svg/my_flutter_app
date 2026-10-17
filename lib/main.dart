import 'package:flutter/material.dart';

import 'pokie/home_screen.dart';

void main() {
  runApp(const PokieApp());
}

class PokieApp extends StatelessWidget {
  const PokieApp({super.key, this.home = const HomeScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lucky Diamonds',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC94A),
          brightness: Brightness.dark,
        ),
      ),
      home: home,
    );
  }
}
