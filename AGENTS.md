# AGENTS

This repository is a Flutter application. The AI agent should treat it as a mobile/desktop Flutter app with standard Dart and Flutter conventions.

## Key facts
- Flutter project at the repository root.
- Dart SDK constraint: `^3.12.2`.
- Primary app entry: `lib/main.dart`.
- Main app structure uses:
  - `lib/main.dart`
  - `lib/data/notifiers.dart`
  - `lib/views/widget_tree.dart`
  - `lib/views/pages/`
  - `lib/views/Widgets/`
- State is currently managed with global `ValueNotifier` objects and `ValueListenableBuilder`.

## Recommended commands
Run from the repository root:
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run`
- `flutter build apk` / `flutter build ios` / `flutter build windows` as needed

## Conventions
- Add new screens/pages in `lib/views/pages/`.
- Add reusable UI components in `lib/views/Widgets/`.
- Keep global state notifiers in `lib/data/notifiers.dart`.
- Preserve `lib/main.dart` as the app entrypoint.
- Use `ThemeData` and `ColorScheme.fromSeed` consistently for theming.

## What to avoid
- Do not modify generated or build artifacts under `build/`, `ios/Flutter/ephemeral/`, `macos/Runner/`, `android/.gradle/`, or IDE/project files like `*.iml`.
- Do not rely on the default `README.md` as architectural documentation; it is the Flutter starter template.

## When editing code
- Prefer using `flutter analyze` to identify syntax, lint, and analyzer issues.
- Keep changes idiomatic to Flutter and Dart.
- For new functionality, wire it into the existing `WidgetTree` and navigation pattern when appropriate.
