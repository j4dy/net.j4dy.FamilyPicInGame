# 🗺️ System Architecture Guide

The **Family Pic-in-Game** application utilizes a highly modular package architecture built on top of Jetpack Compose. This ensures a clean separation between the database storage, general application UI screens, and independent game packages.

---

## 📂 Directory Structure

The codebase is organized in the package namespace `net.j4dy.familypicingame`:

```
app/src/main/java/net/j4dy/familypicingame/
├── MainActivity.kt               # Central Navigation Host & Game Registry
├── model/
│   └── FaceProfile.kt            # Avatar metadata configuration model
├── data/
│   └── FaceStorage.kt            # SharedPrefs CRUD helper & default Canvas drawings
├── ui/
│   ├── theme/                    # Color, Type, and Theme styling systems
│   └── screens/
│       ├── HomeScreen.kt         # Menu dashboard with cosmic animated Canvas
│       ├── FaceManagerScreen.kt  # Circular avatar management grid
│       └── FaceCropScreen.kt     # Multi-touch permissionless crop canvas
└── games/
    ├── GameDescriptor.kt         # Standard game definition blueprints
    ├── common/
    │   └── Vector2D.kt           # 2D geometry vector math utilities
    ├── slingshot/                # Slingshot physics-based launcher game package
    ├── snake/                    # Snake nibbles arcade game package
    ├── flappy/                   # Flappy Flight scrolling obstacle game package
    ├── whack/                    # Whack-a-Monster coordinates grid game package
    └── pacman/                   # Pac-Man classic maze chase game package
```

---

## 💾 Storage & Data Management (`FaceStorage.kt`)

Avatars are managed by the `FaceStorage` class, which combines structured metadata in Android `SharedPreferences` with physical local image files:

1. **Circular Masking**: Cropped images are natively masked using standard Android Canvas transformations and `PorterDuff.Mode.SRC_IN` before saving.
2. **Fallback Vector Drawing**: If no custom profile photos are present on first startup, `FaceStorage` uses a Canvas drawing pipeline to draw 4 default cartoon avatars (an angry red bird, a blue bird, a green pig, and a happy blue monster) and writes them to local storage. This guarantees that the user has immediately playable faces right out of the box.

---

## 🔌 Game Registration Pipeline (How to Add a Game)

Adding new games is designed to be plug-and-play. You do not need to modify any of the existing dashboard screens or manager classes:

1. **Create Package**: Add a package under `games/mygame/` with your custom game state and Compose screen layout.
2. **Declare Descriptor**: Inside `MainActivity.kt`, add a new `GameDescriptor` to the `registeredGames` list:
   ```kotlin
   GameDescriptor(
       id = "my_game_id",
       title = "Family MyGame",
       description = "Munch neon pellets as your favorite family member!",
       route = "game_mygame"
   )
   ```
3. **Register Route**: Inside the `NavHost` in `MainActivity.kt`, add a route pointing to your new screen:
   ```kotlin
   composable("game_mygame") {
       MyGameScreen(onBackClick = { navController.popBackStack() })
   }
   ```
   
*Note: The new game card will automatically render on the main Home Screen with matching glassmorphic cards and cyberpunk border glow animations!*
