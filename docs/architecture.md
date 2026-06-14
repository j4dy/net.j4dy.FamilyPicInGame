# 🗺️ System Architecture Guide

The **Family Pic-in-Game** application utilizes a highly modular package architecture built on top of Flutter. This ensures a clean separation between the database storage, general application UI screens, and independent game packages.

---

## 📂 Directory Structure

The codebase is organized under the `lib/` directory:

```
lib/
├── main.dart                 # Application entry point, NavNavigator router and registry
├── theme.dart                # Cyber neon Color, Type, and Theme styling systems
├── models/
│   ├── face_profile.dart     # Avatar metadata configuration model
│   └── game_descriptor.dart  # Standard game definition blueprints
├── data/
│   └── face_storage.dart     # Handles SharedPreferences CRUD and default Canvas drawings
├── screens/
│   ├── home_screen.dart          # Cosmic menu dashboard with animated radial particles
│   ├── face_manager_screen.dart  # Circular avatar management grid
│   ├── face_crop_screen.dart     # Interactive touch-based circular crop utility
│   └── games/                    # UI screens for each game
│       ├── connect4_game.dart
│       ├── slingshot_game.dart
│       ├── snake_game.dart
│       ├── flappy_game.dart
│       ├── whack_game.dart
│       └── pacman_game.dart
└── games/
    ├── common/
    │   └── vector_2d.dart        # 2D geometry vector math utilities
    ├── connect4/                 # Connect 4 pure game logic state models
    ├── slingshot/                # Slingshot physics state models
    ├── snake/                    # Snake game grid state models
    ├── flappy/                   # Flappy Flight physics models
    ├── whack/                    # Whack coordinates state models
    └── pacman/                   # Pacman chase pathfinder models
```

---

## 💾 Storage & Data Management (`face_storage.dart`)

Avatars are managed by the `FaceStorage` class, which combines structured metadata in Flutter's `SharedPreferences` with physical local image files:

1. **Circular Masking**: Cropped images are natively masked using standard Canvas transformations and circular path clips before saving as PNGs.
2. **Fallback Drawings**: If no custom profile photos are present on first startup, `FaceStorage` uses a `CustomPainter` or standard canvas drawing pipeline to draw 4 default cartoon avatars (an angry red bird, a blue bird, a green pig, and a happy blue monster) and writes them to local storage. This guarantees that the user has immediately playable faces right out of the box.

---

## 🔌 Game Registration Pipeline (How to Add a Game)

Adding new games is designed to be plug-and-play. You do not need to modify any of the existing dashboard screens or manager classes:

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
   
*Note: The new game card will automatically render on the main Home Screen with matching glassmorphic cards and cyberpunk border glow animations!*
