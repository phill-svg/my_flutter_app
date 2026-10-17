# Project notes for Claude

## What this is
Flutter app "Lucky Diamonds": a free-play online pokie (5×3 reels, 10 lines).
Owner wants it playable online (Flutter web via GitHub Pages) and on iOS
(unsigned IPA sideload workflow).

## Ground rules
- Keep it free play: credits have no cash value, no purchases, no cash-out.
  Real-money online pokies can't legally be offered to people in Australia
  (Interactive Gambling Act 2001). Raise this before adding anything like
  buying credits, prizes, or payouts.

## Layout
- `lib/pokie/slot_engine.dart`: pure game logic (reels, paylines, pays).
- `lib/pokie/pokie_screen.dart`: UI. `PokieScreen(engine:)` takes a seeded
  engine in tests.
- `tool/rtp.dart`: RTP simulator. After changing pays or reel strips, run
  `dart run tool/rtp.dart 3000000` and keep RTP around 92–95%.
  `test/slot_engine_test.dart` asserts 88–98%.
- Reel strips are shuffled with a fixed seed per reel (`_strip(counts, seed)`).

## Working in the cloud container
- No Flutter SDK preinstalled. Install with
  `git clone --depth 1 -b stable https://github.com/flutter/flutter.git <scratchpad>/flutter`
  and put its `bin` on PATH. The pubspec needs Dart ≥ 3.12.
- Flutter prints "running as root" warnings; harmless.
- Screenshot the web build with Playwright from
  `/opt/node-tools/node_modules/playwright/index.mjs`. Headless Chromium needs
  `locale: 'en-AU'` on the page (otherwise "Incorrect locale information
  provided" and a blank page) and `--enable-unsafe-swiftshader
  --use-angle=swiftshader` launch args.

## Checks before pushing
`flutter analyze`, `flutter test`, `dart format lib test tool`.
