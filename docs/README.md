# 📚 Family Pic-in-Game Documentation

Welcome to the comprehensive documentation for the **Family Pic-in-Game** mobile application. This project is a cross-platform mobile game suite built with Flutter and Dart, styled in a vibrant neon cyberpunk theme, allowing users to play classic arcade and physics games using customized circular crops of their family members, friends, or pets!

---

## 🗺️ Documentation Directory

Use the links below to explore specific technical and user guides for the project:

1. **[System Architecture](architecture.md)**
   * Package structure and module definitions inside Dart.
   * Model definitions and local data persistence flows (JSON mapping).
   * Guide on how to register and extend new games.
2. **[Game Features & Mechanics](features.md)**
   * Complete mechanics and gameplay parameters for all 5 games (**Slingshot, Snake, Flappy Flight, Whack-a-Monster, Pac-Man**).
   * Physics equations, collision vectors, pathfinding AI, and custom settings.
3. **[Accessibility & Readability Upgrades](accessibility.md)**
   * Detailed breakdown of the font size (enlarged to `22.sp` / equivalent Flutter logical pixels) and button layout enhancements.
   * UI touch targets and visual labeling adjustments for text-labeled header reset buttons.

---

## 🚀 Getting Started

### Prerequisites
* **Flutter SDK**: Make sure you have Flutter installed (`3.x` or newer recommended).
* **IDE**: VS Code or Android Studio with Flutter/Dart plugins installed.
* A connected mobile device (iOS/Android) with developer options enabled, or a running emulator/simulator.

### Build & Run
1. Clone this repository to your workspace.
2. Open the directory in your IDE of choice.
3. Run `flutter pub get` in the root folder to download the required package dependencies.
4. Launch the application:
   * Via CLI:
     ```bash
     flutter run
     ```
   * Via IDE: Press **F5** or click the Run button.

---

## 🔒 Privacy & Data Policy

* **100% On-Device Processing**: The app performs all photo-cropping, profile creation, and game-saving tasks locally. No external APIs, servers, or trackers are used.
* **Permissionless Gallery Selection**: Uses standard OS out-of-process picker mechanisms. The application does **not** request invasive wide read/write storage permissions to your entire gallery.
