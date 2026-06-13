# 📚 Family Pic-in-Game Documentation

Welcome to the comprehensive documentation for the **Family Pic-in-Game** Android application. This app is a native Android game suite styled with a premium neon cyberpunk theme, allowing users to play classic arcade and physics games using customized circular crops of their family members, friends, or pets!

---

## 🗺️ Documentation Directory

Use the links below to explore specific technical and user guides for the project:

1. **[System Architecture](architecture.md)**
   * Package structure and module definitions.
   * Model definitions and data persistence flows.
   * Guide on how to register and extend new games.
2. **[Game Features & Mechanics](features.md)**
   * Complete mechanics and gameplay parameters for all 5 games (**Slingshot, Snake, Flappy Flight, Whack-a-Monster, Pac-Man**).
   * Physics equations, contact contact normals, AI paths, and custom settings.
3. **[Accessibility & Readability Upgrades](accessibility.md)**
   * Detailed breakdown of the font size (enlarged to `22.sp`) and button layout enhancements.
   * UI touch targets and visual labeling adjustments for text-labeled header reset buttons.

---

## 🚀 Getting Started

### Prerequisites
* **Android Studio** (Koala / Ladybug or newer recommended).
* **Android SDK 34** (compileSdk is configured to 34).
* A physical Android device with USB debugging enabled, or an Android Virtual Device (AVD).

### Build & Run
1. Clone this repository to your workspace.
2. Open Android Studio, click **Open...**, and choose the project directory: `[path-to-project]/family-pic-in-game-android/`.
3. Wait for the Gradle sync to complete. The project uses Gradle wrapper `8.6` and Kotlin `1.9.22`.
4. Click the **Run** button (`Shift + F10`) to compile and launch the debug app on your device or emulator.

---

## 🔒 Privacy & Data Policy

* **100% On-Device Processing**: The app performs all photo-cropping, profile creation, and game-saving tasks locally. No external APIs, servers, or trackers are used.
* **Permissionless Gallery Selection**: Uses Android's modern out-of-process Photo Picker (`PickVisualMedia`). The application does **not** request invasive wide read/write storage permissions to your entire gallery.
