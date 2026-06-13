# 🎮 Family Pic-in-Game Mobile Arcade App

A premium, interactive cross-platform mobile application written entirely in **Dart** and built with modern **Flutter**. Players can crop circular photos of family members, friends, or pets directly from their device’s photo library and use them as active characters in classic games (including slingshot physics, retro snake eating, space flappy flight, Whack-a-Monster, and Pac-Man)!

The app is styled with a futuristic, dark-mode neon cyberpunk design (deep cosmic slate, neon cyan, magenta, and electric purple glow) and uses custom canvas-drawn game loops and physics engines.

---

## ✨ Features

### 1. Privacy-Respecting Photo Cropping (`FaceCropScreen` / `FaceStorage`)
* **Permissionless Gallery Access**: Integrates modern OS image selection (such as Android's `PickVisualMedia` picker) to safely select and crop photos **without granting invasive, device-wide storage permissions**.
* **Gestures Crop Canvas**: Features dynamic pinch-to-zoom (scaling) and drag-to-pan (offsetting) multi-touch canvas controls.
* **Matrix Transformation**: Safely maps physical touch drag vectors back to the raw image coordinates, handles downsampling to prevent Out-of-Memory crashes, masks the image into a perfect circle, and saves it locally.

### 2. Family Face Manager (`FaceManagerScreen` & `FaceStorage`)
* **Staggered Cards Grid**: View, add, or delete your customized character heads.
* **Dynamic Vector Avatars**: If no custom photos are configured, the database automatically draws 4 cute cartoon faces (an angry red bird, a blue bird, a green pig, and a blue cookie monster) programmatically on a canvas and writes them as PNGs, ensuring a rich visual experience immediately upon first boot!

### 3. Family Slingshot (Physics-Based)
* **High-Impact Velocity & Deflection**: Features dynamic slingshot physics where bird characters plow through wood and glass blocks.
* **Plow-Through Block Demolition**: Velocity calculations contacto normal splits components: $v_{ref} = v - (1 + e)(v \cdot n)n$ (mixing 80% forward momentum with 20% reflected contact normal). Glass blocks decay speed by 10%, wood blocks by 20%.
* **Falling Debris & Gravity**: Supporting obstacle blocks fall down realistically under gravity when pillars beneath them are destroyed, settling onto lower blocks and squashing targets.
* **Trajectory Prediction**: Aiming elastic neon cords draw a dotted aim trajectory for 120 simulation frames.
* **Level Progression**: Includes 3 distinct levels ("Twin Towers", "Pyramid Arch", and "Multi-Layer Fort") with custom architectural layouts.

### 4. Family Nibbles (Snake Style)
* **Alternating Family Body Parts**: Select who is the snake head and who is the food. When the head eats food, the snake grows and **alternates its body segments using all the other cropped faces in your manager!**
* **Portal Ripple Boundaries**: When the snake head touches a boundary wall, it wraps to the other side of the grid. Connectors are hidden during wrap frames. Wraps trigger dual-color ripples (Electric Cyan at exit, Neon Pink at entrance) and sparkles.
* **Dual Controllers**: Swipe gestures on the grid, or use a high-precision visual overlay D-Pad control dock.

### 5. Family Flappy Flight
* **Difficulty Settings**: Features gap difficulties: Space Cadet (Easy - 340 px), Pilot (Medium - 280 px), and Astronaut (Hard - 220 px).
* **Backpack Spacesuits**: Draws character faces inside astronaut helmets with capsules flying through scrolling stars.

### 6. Whack-a-Monster
* **Reaction Grid**: Whack neon opponent monsters (Neon Pink) from 12 portal tunnels but avoid whacking your family teammates (Electric Cyan).
* **Speed Customizations**: Supports 1.0x Slow, 1.5x Normal, 2.0x Fast, and 3.0x Insane multipliers.

### 7. Family Pac-Man
* **Connected Maze**: Eat pellets inside a blue neon connected maze outline.
* **Authentic Ghost AI**: Blinky (chase), Pinky (ambush), Inky (mirror), and Clyde (scatter) navigate paths natively.
* **Safe Copy Iterations**: Snapshot-safe copy lists are iterated during player-ghost collisions to prevent thread concurrency crashes.

---

## 🛠️ Technology Stack

* **Language**: 100% Dart
* **Framework**: Flutter SDK (Cross-platform)
* **Rendering**: Custom Painter canvas drawing engines
* **Storage**: Local SQLite or Shared Preferences file path mappings

---

## 📂 Modular Architecture & Layout

To support seamless additions of new games, the codebase uses a clean, feature-by-feature modular structure:

```
lib/
├── main.dart                 # Application entry point, NavNavigator router and registry
├── theme.dart                # Cyber neon Color, Type, and Theme definitions
├── models/
│   ├── face_profile.dart     # Avatar metadata (id, name, path, isDefault)
│   └── game_descriptor.dart  # Game card descriptor blueprints
├── data/
│   └── face_storage.dart     # Handles local JSON persistence, file CRUD, and canvas vector generation
├── screens/
│   ├── home_screen.dart          # Cosmic menu dashboard with animated radial particles
│   ├── face_manager_screen.dart  # Staggered grid view of faces
│   ├── face_crop_screen.dart     # Interactive touch-based circular crop utility
│   └── games/                    # Game UI Screens
│       ├── slingshot_game.dart
│       ├── snake_game.dart
│       ├── flappy_game.dart
│       ├── whack_game.dart
│       └── pacman_game.dart
└── games/
    ├── common/
    │   └── vector_2d.dart        # 2D algebra physics helper
    ├── slingshot/                # Slingshot physics state models
    ├── snake/                    # Snake game grid state models
    ├── flappy/                   # Flappy Flight physics models
    ├── whack/                    # Whack coordinates state models
    └── pacman/                   # Pacman chase pathfinder models
```

---

### ➕ How to Add a New Game

1. **Create game files**: Implement your CustomPainter canvas game screen in `lib/screens/games/my_game.dart` and its state in `lib/games/my_game/`.
2. **Register Descriptor**: Open `lib/main.dart` and append a new `GameDescriptor` to the `_gamesList`:
   ```dart
   GameDescriptor(
     id: 'mygame',
     title: 'Family MyGame',
     description: 'Brief funny description...',
     route: 'mygame_game',
   )
   ```
3. **Register Route enum**: Append your game screen to the `AppScreen` enum in `lib/main.dart`:
   ```dart
   enum AppScreen {
     ...,
     gameMyGame
   }
   ```
4. **Link Navigation**: Add mapping inside `_onGameSelect` and `MainNavigator.build`:
   ```dart
   // inside _onGameSelect
   case 'mygame':
     _navigateToScreen(AppScreen.gameMyGame);
     break;
     
   // inside build
   case AppScreen.gameMyGame:
     return MyGameScreen(
       faceStorage: _faceStorage!,
       onBackClick: () => _navigateToScreen(AppScreen.home),
     );
   ```
5. **Done!** The dashboard will automatically render the new game card with cyber glass borders.

---

## 🚀 How to Run the Project

Ensure you have the Flutter SDK installed on your system.

1. **Verify Environment**: Run `flutter doctor` in your terminal to check dependencies.
2. **Retrieve Packages**: Run `flutter pub get` in the root directory.
3. **Run on Emulator / Device**:
   * Connect your target mobile device or start an emulator.
   * Run the app via CLI:
     ```bash
     flutter run
     ```
   * Alternatively, open the directory in VS Code or Android Studio and press **F5** (Run).

---

## 🔒 Privacy Policy

**Family Pic-in-Game** is built with your privacy as our absolute highest priority. 

### 1. 100% Local Processing (On-Device)
* **No Server Uploads**: Every image you pick, crop, or process remains **entirely on your local physical device**. We do not run any cloud servers, databases, or external APIs to upload or store your family photos.
* **No Analytics or Tracking**: We do not integrate any tracking SDKs, advertising IDs, analytics platforms, or profiling cookies. Your gameplay data, selected names, and high scores stay 100% offline.

### 2. Privacy-Friendly Image Access
* **Zero Invasive Permissions**: Unlike older apps, **Family Pic-in-Game does NOT ask for or require device-wide read/write permissions to your gallery or files**. The operating system isolatedly grants temporary, secure access only to the single photo you explicitly tap and select.

### 3. Data Deletion
* **Instant Removal**: You have absolute control. If you delete a custom family profile card inside the **Face Manager**, the associated cropped image file and its name entry are permanently deleted from your device's private application storage immediately.
* **Uninstall Cleanse**: Uninstalling the application automatically and completely wipes all stored face profiles and settings from your device.
