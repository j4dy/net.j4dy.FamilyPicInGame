# ♿ Accessibility & Readability Upgrades

To ensure that the application is fully readable, accessible, and comfortable to play for users of all ages, we implemented a complete upgrade to our typography, buttons, and touch target sizes.

---

## 📐 Button Font Sizing

Previously, the retry and game-over buttons were set to an unspecified default or a small `12.sp` / `14.sp` font size. We upgraded all central buttons on overlay menus and screen footers:

* **Upgrade to `22.sp`**: All game over, start, restart, and navigation action buttons (such as `RETRY`, `PLAY AGAIN`, `START MATCH`, `NEXT LEVEL`, and `ROLES`) are set to bold, high-contrast **`22.sp`** font size.
* **Expanded Padding**: Touch target padding has been increased to a highly comfortable `horizontal = 24.dp, vertical = 14.dp` container format.
* **Enlarged Icons**: Accompanying vector icons (e.g., refresh circular loops, arrow indicators, play icons) are scaled up to **`24.dp`** or **`26.dp`** to align seamlessly with the larger text layout.

---

## 🏷️ Labeled Reset Button Enhancements

To eliminate confusion during gameplay, obscure in-game reset buttons that were previously represented by small, icon-only actions have been completely overhauled:

1. **Top Bar Actions**: The top app bar reset action inside **Snake, Pac-Man, Whack-a-Monster, and Flappy Flight** has been changed from an `IconButton` to a prominent `TextButton` displaying a bold **`RESET`** label at **`18.sp`** alongside a matching refresh icon.
2. **Floating Slingshot Button**: In the physics-based Slingshot game, the floating top-right refresh icon has been replaced with a capsule-shaped neon-bordered `Button` displaying a bold **`RESET`** label at **`18.sp`** with its refresh icon.

These updates guarantee that key game actions are readable, visually distinct, and easily clickable on devices with varying pixel densities.
