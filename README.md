# Velocity Mental Math

**Velocity Mental Math** is a Flutter-based educational game designed to help children practice mental arithmetic through fast, interactive exercises and progressive difficulty.

The project includes support for mobile platforms and web deployment, with a focus on simple gameplay, clean UI, and an engaging learning experience.

---

## Overview

Velocity was built as an educational mobile/web game where users answer arithmetic questions in a game-like flow. The goal is to make mental math practice more interactive and enjoyable, especially for younger learners.

The app focuses on:

- Quick arithmetic practice
- Progressive difficulty
- Simple and responsive UI
- Educational game mechanics
- Mobile-first experience
- Web compatibility through Flutter Web

---

## Features

- Mental arithmetic question generation
- Progressive difficulty levels
- Interactive answer flow
- Score/progress tracking
- Child-friendly interface
- Mobile and web support
- Flutter-based cross-platform structure

---

## Tech Stack

- Flutter
- Dart
- Flutter Web
- Android build support
- iOS project structure
- Optional Node.js server file for web/server support

---

## Project Structure

```text
velocity-mental-math/
│
├── android/              # Android platform files
├── ios/                  # iOS platform files
├── web/                  # Flutter Web files
├── lib/                  # Main Dart/Flutter source code
├── assets/               # Images, sounds, icons, and other app assets
├── test/                 # Flutter tests
├── tools/                # Utility scripts or project tools
├── ANDROID_SETUP.md      # Android setup notes
├── analysis_options.yaml # Dart analysis configuration
├── pubspec.yaml          # Flutter dependencies and project config
├── pubspec.lock          # Locked dependency versions
├── server.js             # Optional web/server support file
└── README.md
```

---

## How to Run Locally

### 1. Install Flutter

Make sure Flutter is installed and configured.

Check installation:

```bash
flutter doctor
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run on a connected device or emulator

```bash
flutter run
```

### 4. Run on web

```bash
flutter run -d chrome
```

---

## Build Commands

### Android build

```bash
flutter build apk
```

### Web build

```bash
flutter build web
```

If using the optional `server.js` file to serve the web build:

```bash
node server.js
```

---

## Development Focus

This project focuses on building a complete educational game experience using Flutter.

Main development areas:

- Structuring a Flutter project
- Building reusable UI components
- Managing game logic
- Handling user input
- Designing progressive difficulty
- Supporting both mobile and web targets
- Creating an educational UX for children

---

## Testing

Run Flutter tests with:

```bash
flutter test
```

Testing can be expanded to cover:

- Question generation logic
- Answer validation
- Score calculation
- Difficulty progression
- UI behavior

---

## Screenshots

Add screenshots in a `screenshots/` folder and reference them here.

Example:

```md
![Home Screen](screenshots/home.png)
![Game Screen](screenshots/game.png)
![Results Screen](screenshots/results.png)
```

---

## Possible Improvements

Planned or possible future improvements:

- Add user profiles
- Add more arithmetic modes
- Add daily challenges
- Add animations and sound effects
- Add parent/teacher dashboard
- Add performance analytics
- Add multiplayer or challenge mode
- Improve test coverage
- Improve web deployment workflow

---

## Project Status

This project is under active development.

Current focus:

- Improving the gameplay flow
- Cleaning the UI
- Preparing mobile and web builds
- Improving documentation and test coverage

---

## License

This project is currently a personal educational software project. A formal license may be added later.
