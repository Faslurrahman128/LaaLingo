# LaaLingo

LaaLingo is a Flutter-based language learning app focused on practical skill development through reading, writing, listening, speaking, quizzes, and live instructor support.

## Core Features

- Interactive lessons for all major language skills
- Writing and speaking practice with evaluation workflows
- Quiz and challenge modules for revision and scoring
- Translator and listening practice screens
- Leaderboard and progress tracking
- Community chat between learners
- Instructor and learner flows (including instructor-specific views)
- Authentication and password recovery flows powered by Supabase

## Tech Stack

- Flutter (Dart)
- Supabase (Auth + backend data)
- Hive (local storage)
- Firebase platform files included for mobile configuration

## Project Structure

- `lib/` → app source code (screens, features, auth, utils)
- `assets/` → icons, images, and local static resources
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` → platform projects
- `supabase/` → local Supabase config and functions

## Getting Started

### 1) Clone

```bash
git clone https://github.com/Faslurrahman128/LaaLingo.git
cd LaaLingo
```

### 2) Install dependencies

```bash
flutter pub get
```

### 3) Run the app

```bash
flutter run
```

## Build

### Android APK (release)

```bash
flutter build apk --release
```

Generated output:

`build/app/outputs/flutter-apk/app-release.apk`

### Web (release)

```bash
flutter build web
```

## Configuration Notes

- Keep production keys/secrets out of version control.
- Verify Supabase URL/key setup in your app config before production deployment.
- For Android/iOS release publishing, configure signing and bundle identifiers as needed.

## Contributing

Contributions are welcome. Open an issue for bug reports or feature requests, and submit a pull request with clear change notes.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

