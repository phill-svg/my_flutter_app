# Lucky Diamonds

A free-play 5-reel pokie built with Flutter. It runs on the web, iOS, Android
and desktop. Players spin with play credits that have no cash value; there are
no real-money bets, purchases or payouts.

## How it plays

- 5 reels × 3 rows, 10 fixed paylines, wins pay left to right.
- 💎 Wild substitutes for everything except ⭐ Scatter, and pays on its own.
- ⭐ Scatter pays anywhere on the reels (3, 4 or 5) as a multiple of the total bet.
- Line bet 1–20 credits per line, auto spin, and a free top-up when credits run out.
- Return to player is about 93% (check with `dart run tool/rtp.dart`).

## Code

| Path | What it is |
| --- | --- |
| `lib/pokie/home_screen.dart` | Homepage with Play now and How to play |
| `lib/pokie/slot_engine.dart` | Reel strips, paylines, pay table and win evaluation (pure Dart, no UI) |
| `lib/pokie/pokie_screen.dart` | The machine UI: animated reels, meters, controls, pay table sheet |
| `tool/rtp.dart` | Simulates spins to estimate return to player after changing pays or reels |
| `test/` | Engine rules, RTP range, and widget tests |

## Run it

```sh
flutter pub get
flutter run -d chrome      # play in the browser
flutter test
```

## Put it online

`.github/workflows/deploy-web.yml` builds the web version and publishes it to
GitHub Pages. One-time setup: in the repo's **Settings → Pages**, set
**Source** to **GitHub Actions**. Then run the workflow from the **Actions**
tab. The game will be at `https://<user>.github.io/my_flutter_app/`.

`.github/workflows/unsigned-ipa.yml` still builds an unsigned iOS IPA for
sideloading.
