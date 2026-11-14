# truefit

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## TrueFit AI (Flutter / Dart)

Dart version of the TrueFit web app: welcome and sign-in, home lookbook, Fit Studio (named fit profiles, auto-capture photo scan, measurement sliders), Book Fitting (lookbook or your own inspiration photo), Saved Looks, My Orders with studio messages, Tailor Studio Desk and cut-sheets. Data is saved on the device.

The AI calls go to the existing `server.ts` (`/api/fit-analyze`, `/api/style-analyze`), which keeps the Gemini key off the phone.

- Web, served by `server.ts`: `flutter build web` and serve `build/web`; the app calls `/api/...` on the same site.
- Android: `flutter build apk --dart-define=API_BASE=https://your-truefit-server`

## One codebase, several tailors (white-label)
Each client's name, colours, studio, outfits, wording and on-device storage live in `lib/brand.dart`
(StitchPerfect photos are in `assets/images/sp/`). Android gets a separate app ID per client, so the apps
can be installed side by side.

| Client | Web build | Android build |
| --- | --- | --- |
| TrueFit Studio (Ifeoma Couture) | `flutter build web --dart-define=API_BASE=...` | `flutter build apk --flavor truefit --dart-define=API_BASE=...` |
| StitchPerfect (Kemi Stitches) | `flutter build web --dart-define=BRAND=stitchperfect --dart-define=API_BASE=...` | `flutter build apk --flavor stitchperfect --dart-define=BRAND=stitchperfect --dart-define=API_BASE=...` |

Live: TrueFit Studio https://truefit-app.gabis-chaser.workers.dev · StitchPerfect https://stitchperfect-app.gabis-chaser.workers.dev
Both currently use the AI server https://truefit-ai.gabis-chaser.workers.dev.
