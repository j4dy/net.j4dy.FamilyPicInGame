# 🎮 Family Pic-in-Game Android App

A premium, interactive native Android application written entirely in **Kotlin** and built with modern **Jetpack Compose**. Players can crop circular photos of family members, friends, or pets directly from their device’s photo library and use them as active characters in classic games (a high-velocity slingshot game and a classic snake game)!

The app is styled with a futuristic, dark-mode neon cyberpunk design (deep cosmic slate, neon cyan, magenta, and electric purple glow) and uses custom canvas-drawn game loops and physics engines.

---

## ✨ Features

### 1. Privacy-Respecting Photo Cropping (`FaceCropScreen`)
* **Permissionless Visual Picker**: Integrates Android's modern `PickVisualMedia` picker. The user can safely pick and crop photos **without granting invasive, device-wide storage permissions**.
* **Gestures Crop Canvas**: Features dynamic pinch-to-zoom (scaling) and drag-to-pan (offsetting) multi-touch canvas controls.
* **Matrix Transformation**: Safely maps physical touch drag vectors back to the raw bitmap coordinates, handles downsampling to prevent Out-of-Memory crashes, masks the image into a perfect circle, and saves it locally as a PNG.

### 2. Family Face Manager (`FaceManagerScreen` & `FaceStorage`)
* **Staggered Cards Grid**: View, add, or delete your customized character heads.
* **Dynamic Vector Avatars**: If no custom photos are configured, the database automatically draws 4 cute cartoon faces (an angry red bird, a blue bird, a green pig, and a blue cookie monster) programmatically on a canvas and writes them as PNGs, ensuring a rich visual experience immediately upon first boot!

### 3. Family Slingshot (Angry Birds Style)
* **Spacious Landscape Playfield**: The gameplay canvas dynamically locks into Landscape mode, re-mapping coordinates to a standard `1280x720` virtual resolution.
* **High-Impact Velocity (5.3x Upgrade)**: The flight intensity is scaled to `0.85f` (a major upgrade) to make launching feel incredibly satisfying and high-speed.
* **Elastic Bands & Prediction**: Stretchable neon pink elastic lines hold the bird, while a projection math engine simulates gravity ($g=0.45$) forward for 30 ticks to draw real-time trajectory dots.
* **Destructible wood/glass defenses**: AABB collision physics demolish wood pillars and glass roof frames. Targets explode into multi-colored gravity particle debris with custom screen-shake effects!

### 4. Family Nibbles (Snake Style)
* **Dual Controllers**: Play comfortably using swipe-to-turn gestures on the grid, or use a high-precision visual overlay D-Pad control dock.
* **Alternating Family Body Parts**: Select who is the snake head and who is the food. When the head eats food, the snake grows and **alternates its body segments using all the other cropped faces in your manager!** Enjoy watching your family members chase after food in a funny tail chain.
* **Chomp Sparkles**: Real-time score multiplier trackers and sparkling burst particles.

---

## 🛠️ Technology Stack

* **Language**: 100% Kotlin
* **UI Framework**: Jetpack Compose (BOM `2023.08.00`)
* **Material Design**: Material 3 Design Tokens
* **Navigation**: Compose Navigation (`2.7.7`)
* **Graphics**: Custom Canvas, PorterDuff masking, and Matrix transforms
* **Build System**: Gradle 8.6 (Kotlin DSL compatible)

---

## 📂 Modular Architecture & Easy Expansion

To support seamless additions of new games, the codebase uses a clean, feature-by-feature modular structure:

```
/app/src/main/java/com/familyface/games/
├── MainActivity.kt        # Sets up NavHost and registers game descriptors
├── model/
│   └── FaceProfile.kt     # Profile metadata (id, name, path, isDefault)
├── data/
│   └── FaceStorage.kt     # Handles SharedPreferences CRUD and default canvas drawings
├── ui/
│   ├── theme/             # Cyber neon Color, Type, and Theme definitions
│   └── screens/
│       ├── HomeScreen.kt          # Cosmic menu dashboard with animated radial orbs
│       ├── FaceManagerScreen.kt   # Staggered grid view of faces
│       └── FaceCropScreen.kt      # Interactive touch-based circular crop utility
└── games/
    ├── GameDescriptor.kt          # Blueprints for game registrations
    ├── common/
    │   └── Vector2D.kt            # 2D algebra physics helper
    ├── slingshot/                 # Physics Slingshot Package (Angry Birds Clone)
    │   ├── PhysicsEngine.kt / SlingshotGameState.kt
    │   └── SlingshotGameScreen.kt
    └── snake/                     # Nibbles Arcade Package (Snake Clone)
        ├── SnakeGameState.kt
        └── SnakeGameScreen.kt
```

### ➕ How to Add a New Game
1. Create a new package under `com.familyface.games.games.yourgame`.
2. Implement your custom game loop Canvas.
3. Open `MainActivity.kt` and add a new `GameDescriptor` to the `registeredGames` list:
   ```kotlin
   GameDescriptor(
       id = "your_game_id",
       title = "My Family Game",
       description = "Brief funny description...",
       route = "game_yourgame"
   )
   ```
4. Define your route in the `NavHost` block:
   ```kotlin
   composable("game_yourgame") {
       YourGameScreen(onBackClick = { navController.popBackStack() })
   }
   ```
5. **Boom!** Your new game automatically registers, renders on the HomeScreen selector with premium cyberpunk borders, and is fully playable!

---

## 🚀 How to Run in Android Studio

1. **Launch Android Studio** (Ladybug, Koala, or newer versions recommended).
2. Choose **Open...** and select the folder:
   `[scratch]/family-pic-in-game-android/`
3. Wait for the IDE to sync the Gradle build files. It uses **Gradle 8.6** and **Kotlin 1.9.22** (pre-loaded inside the Gradle wrapper configurations).
4. Connect an Android device (USB Debugging enabled) or start a Virtual Device (AVD Emulator).
5. Click the **Run** green arrow button (`Shift + F10`) to deploy and play!
